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
                            .tint(.primary) // Use theme primary color for spinner
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

// MARK: - StatusBadge Component
struct StatusBadge: View {
    let status: BetStatus
    
    private var statusColor: Color {
        switch status {
        case .pending:
            return .statusWarning
        case .active:
            return .primary
        case .cancelled:
            return .textSecondary
        case .won:
            return .statusSuccess
        case .lost:
            return .statusError
        }
    }
    
    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
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

#Preview {
    MyBetsView()
}
