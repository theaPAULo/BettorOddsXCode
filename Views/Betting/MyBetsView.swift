//
//  MyBetsView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 2.0.1
//

import SwiftUI

struct MyBetsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = MyBetsViewModel()
    @State private var selectedFilter = BetFilter.active
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(BetFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Bets List
                ScrollView {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if viewModel.bets.isEmpty {
                        emptyStateView
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredBets(for: selectedFilter)) { bet in
                                BetCard(bet: bet) {
                                    viewModel.cancelBet(bet)
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding()
                    }
                }
                .refreshable {
                    viewModel.loadBets()
                }
            }
            .navigationTitle("My Bets")
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .onAppear {
                viewModel.loadBets()
            }
            // Listen for navigation notification
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToMyBets"))) { _ in
                viewModel.loadBets()
            }
        }
    }
    
    // MARK: - Supporting Views
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "ticket")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.Text.secondary)
            
            Text("No Bets Found")
                .font(.headline)
                .foregroundColor(AppTheme.Text.primary)
            
            Text("Your bets will appear here once you place them")
                .font(.subheadline)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .padding(.top, 40)
    }
}

// MARK: - ViewModel
class MyBetsViewModel: ObservableObject {
    @Published private(set) var bets: [Bet] = []
    @Published private(set) var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let betsManager = BetsManager.shared
    
    init() {
        loadBets()
    }
    
    func loadBets() {
        isLoading = true
        
        Task { @MainActor in
            do {
                bets = try await betsManager.fetchBets()
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
    
    func filteredBets(for filter: MyBetsView.BetFilter) -> [Bet] {
        switch filter {
        case .active:
            return bets.filter { $0.status == .active || $0.status == .pending }
        case .completed:
            return bets.filter { $0.status == .won || $0.status == .lost }
        case .all:
            return bets
        }
    }
    
    func cancelBet(_ bet: Bet) {
        guard bet.canBeCancelled else { return }
        
        isLoading = true
        
        Task { @MainActor in
            do {
                // Simulate network delay
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                if let index = bets.firstIndex(where: { $0.id == bet.id }) {
                    var cancelledBet = bets[index]
                    cancelledBet.status = .cancelled
                    bets[index] = cancelledBet
                }
                
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
}

// MARK: - Bet Filter
extension MyBetsView {
    enum BetFilter: String, CaseIterable {
        case active = "Active"
        case completed = "Completed"
        case all = "All"
    }
}

#Preview {
    MyBetsView()
}
