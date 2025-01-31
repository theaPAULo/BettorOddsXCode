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
                            .foregroundColor(.textPrimary)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Bets List
                ScrollView {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                            .tint(.primary)
                    } else if viewModel.bets.isEmpty {
                        emptyStateView
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredBets(for: selectedFilter)) { bet in
                                BetCard(bet: bet) {
                                    print("🎲 Cancel action received from BetCard")
                                    Task {
                                        print("🎲 Starting cancellation task")
                                        await viewModel.cancelBet(bet)
                                        print("✅ Cancellation task completed")
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
            }
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("My Bets")
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

#Preview {
    MyBetsView()
}
