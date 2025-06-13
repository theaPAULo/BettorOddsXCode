//
//  BaseViewModel.swift
//  BettorOdds
//
//  Created by Claude on 6/13/25
//  Version: 1.0.0 - Base class for all ViewModels with common functionality
//

import Foundation
import Combine
import SwiftUI

// MARK: - Loading State

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case failed(AppError)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var error: AppError? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Base ViewModel Protocol

@MainActor
protocol BaseViewModelProtocol: ObservableObject {
    var loadingState: LoadingState { get set }
    var currentError: AppError? { get set }
    var showError: Bool { get set }
    
    func clearError()
    func handleError(_ error: AppError)
    func setLoading(_ loading: Bool)
}

// MARK: - Base ViewModel Implementation

@MainActor
class BaseViewModel: BaseViewModelProtocol, ObservableObject {
    
    // MARK: - Published Properties
    @Published var loadingState: LoadingState = .idle
    @Published var currentError: AppError?
    @Published var showError = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let logger = AppLogger.shared
    
    // MARK: - Computed Properties
    
    var isLoading: Bool {
        loadingState.isLoading
    }
    
    var hasError: Bool {
        currentError != nil
    }
    
    // MARK: - Initialization
    
    init() {
        setupErrorHandling()
    }
    
    // MARK: - Public Methods
    
    /// Clears the current error
    func clearError() {
        currentError = nil
        showError = false
        
        if case .failed = loadingState {
            loadingState = .idle
        }
    }
    
    /// Handles an error with unified logic
    func handleError(_ error: AppError) {
        currentError = error
        showError = true
        loadingState = .failed(error)
        
        // Log error if enabled
        logger.logError(error, context: String(describing: type(of: self)))
    }
    
    /// Sets loading state
    func setLoading(_ loading: Bool) {
        if loading {
            loadingState = .loading
            clearError()
        } else {
            if loadingState == .loading {
                loadingState = .loaded
            }
        }
    }
    
    /// Executes an async operation with automatic error handling
    func executeAsync<T>(
        _ operation: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void = { _ in },
        onError: @escaping (AppError) -> Void = { _ in }
    ) {
        Task {
            setLoading(true)
            
            do {
                let result = try await operation()
                onSuccess(result)
                setLoading(false)
            } catch let error as AppError {
                handleError(error)
                onError(error)
                setLoading(false)
            } catch {
                let appError = AppError.unknown(error.localizedDescription)
                handleError(appError)
                onError(appError)
                setLoading(false)
            }
        }
    }
    
    /// Executes an async operation that returns a Result
    func executeAsyncResult<T>(
        _ operation: @escaping () async -> Result<T, AppError>,
        onSuccess: @escaping (T) -> Void = { _ in },
        onError: @escaping (AppError) -> Void = { _ in }
    ) {
        Task {
            setLoading(true)
            
            let result = await operation()
            
            switch result {
            case .success(let value):
                onSuccess(value)
                setLoading(false)
            case .failure(let error):
                handleError(error)
                onError(error)
                setLoading(false)
            }
        }
    }
    
    /// Retries the last failed operation
    func retry(_ operation: @escaping () async -> Void) {
        guard case .failed(let error) = loadingState, error.isRetryable else {
            return
        }
        
        Task {
            await operation()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupErrorHandling() {
        // Auto-clear errors after a delay if they're not critical
        $currentError
            .compactMap { $0 }
            .filter { !$0.requiresUserAction }
            .delay(for: .seconds(AppConfiguration.UI.defaultAnimationDuration + 2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.clearError()
            }
            .store(in: &cancellables)
    }
}

// MARK: - App Logger

/// Centralized logging system
class AppLogger {
    static let shared = AppLogger()
    
    private init() {}
    
    func logError(_ error: AppError, context: String) {
        guard AppConfiguration.Logging.enableConsoleLogging,
              error.shouldLog else { return }
        
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let message = "[\(timestamp)] ❌ \(context): \(error.localizedDescription)"
        
        print(message)
        
        // In production, you might want to send this to a logging service
        if AppConfiguration.Logging.enableFileLogging {
            writeToLogFile(message)
        }
    }
    
    func logInfo(_ message: String, context: String) {
        guard AppConfiguration.Logging.enableConsoleLogging else { return }
        
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] ℹ️ \(context): \(message)"
        
        print(logMessage)
        
        if AppConfiguration.Logging.enableFileLogging {
            writeToLogFile(logMessage)
        }
    }
    
    func logDebug(_ message: String, context: String) {
        guard AppConfiguration.Logging.enableConsoleLogging,
              AppConfiguration.Logging.minLogLevel.rawValue <= AppConfiguration.Logging.LogLevel.debug.rawValue else { return }
        
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] 🐛 \(context): \(message)"
        
        print(logMessage)
    }
    
    private func writeToLogFile(_ message: String) {
        // Implementation for file logging
        // This would write to a log file in the app's documents directory
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logFileURL = documentsPath.appendingPathComponent("app.log")
        let logEntry = message + "\n"
        
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Specialized Base ViewModels

/// Base ViewModel for views that fetch data
@MainActor
class DataViewModel<T>: BaseViewModel {
    @Published var data: T?
    @Published var isRefreshing = false
    
    /// Refreshes data with pull-to-refresh support
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        await loadData()
    }
    
    /// Override this method in subclasses
    func loadData() async {
        fatalError("loadData() must be implemented by subclass")
    }
}

/// Base ViewModel for views that manage lists
@MainActor
class ListViewModel<T: Identifiable>: BaseViewModel {
    @Published var items: [T] = []
    @Published var isRefreshing = false
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .ascending
    @Published var filterOptions: Set<String> = []
    
    enum SortOrder {
        case ascending
        case descending
    }
    
    var filteredItems: [T] {
        // Override in subclasses to implement filtering logic
        return items
    }
    
    /// Refreshes the list
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        await loadItems()
    }
    
    /// Adds an item to the list
    func addItem(_ item: T) {
        items.append(item)
    }
    
    /// Removes an item from the list
    func removeItem(_ item: T) {
        items.removeAll { $0.id == item.id }
    }
    
    /// Updates an item in the list
    func updateItem(_ item: T) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }
    
    /// Override this method in subclasses
    func loadItems() async {
        fatalError("loadItems() must be implemented by subclass")
    }
}

// MARK: - ViewModifier for Error Handling

struct ErrorHandlingModifier: ViewModifier {
    @ObservedObject var viewModel: BaseViewModel
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.clearError()
                }
                
                if let error = viewModel.currentError, error.isRetryable {
                    Button("Retry") {
                        // This would need to be implemented per view
                        viewModel.clearError()
                    }
                }
            } message: {
                if let error = viewModel.currentError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error.localizedDescription)
                        
                        if let suggestion = error.recoverySuggestion {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
    }
}

extension View {
    func errorHandling<VM: BaseViewModel>(viewModel: VM) -> some View {
        modifier(ErrorHandlingModifier(viewModel: viewModel))
    }
}
