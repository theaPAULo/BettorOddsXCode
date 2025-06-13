//
//  MyBetsView.swift
//  BettorOdds
//
//  Created by Claude on 2/2/25
//  Version: 2.1.0
//

import SwiftUI
import Combine
import Firebase
import FirebaseAuth

struct MyBetsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = MyBetsViewModel()
    @State private var selectedFilter = BetFilter.active
    @State private var scrollOffset: CGFloat = 0
    
    // MARK: - Private Types
    private struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    
    private struct ScrollOffsetModifier: ViewModifier {
        let coordinateSpace: String
        @Binding var offset: CGFloat
        
        func body(content: Content) -> some View {
            content
                .overlay(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: proxy.frame(in: .named(coordinateSpace)).minY
                            )
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    offset = value
                }
        }
    }
    
    // MARK: - ViewModel
    @MainActor
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
        
        func cancelBet(_ bet: Bet) async {
            print("🎲 ViewModel received cancel request for bet: \(bet.id)")
            isLoading = true
            
            do {
                print("🎲 Calling BetsManager.cancelBet")
                try await BetsManager.shared.cancelBet(bet.id)
                print("✅ Bet successfully cancelled")
                await loadBets()
                print("✅ Bets reloaded")
            } catch {
                print("❌ Error cancelling bet: \(error)")
                errorMessage = error.localizedDescription
                showError = true
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Primary").opacity(0.2),
                        Color.white.opacity(0.1),
                        Color("Primary").opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .hueRotation(.degrees(scrollOffset / 2)) // Add animated hue rotation
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Text("My Bets")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color("Primary"))
                        .shadow(color: Color("Primary").opacity(0.3), radius: 2, x: 0, y: 2)
                        .padding(.top, -60)
                        .padding(.bottom, 4)
                    
                    // Filter Picker
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(BetFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // Bets List
                    ScrollView {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.top, 20)
                                .tint(.primary)
                        } else if viewModel.bets.isEmpty {
                            emptyStateView
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredBets(for: selectedFilter)) { bet in
                                    BetCard(bet: bet) {
                                        Task {
                                            await viewModel.cancelBet(bet)
                                        }
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
                    .modifier(ScrollOffsetModifier(coordinateSpace: "scroll", offset: $scrollOffset))
                    .coordinateSpace(name: "scroll")
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
                    .foregroundColor(.statusError)
            }
            .onAppear {
                viewModel.loadBets()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToMyBets"))) { _ in
                viewModel.loadBets()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Supporting Views
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "ticket")
                .font(.system(size: 50))
                .foregroundColor(.textSecondary)
            
            Text("No Bets Found")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Text("Your bets will appear here once you place them")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .padding(.top, 40)
    }
}

// MARK: - BetFilter
extension MyBetsView {
    enum BetFilter: String, CaseIterable {
        case active = "Active"
        case completed = "Completed"
        case all = "All"
    }
}

// MARK: - Preview
#Preview {
    MyBetsView()
}
