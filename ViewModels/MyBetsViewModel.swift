import SwiftUI
import FirebaseAuth

@MainActor
class MyBetsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var bets: [Bet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    var totalBets: Int { bets.count }
    var wonBets: Int { bets.filter { $0.status == .won }.count }
    var lostBets: Int { bets.filter { $0.status == .lost }.count }
    var pendingBets: Int { bets.filter { $0.status == .pending || $0.status == .active }.count }
    
    var winRate: Int {
        let completedBets = wonBets + lostBets
        guard completedBets > 0 else { return 0 }
        return Int(Double(wonBets) / Double(completedBets) * 100)
    }
    
    // MARK: - Methods
    func loadBets() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let betRepository = BetRepository()
            // FIXED: Use correct method name
            let userBets = try await betRepository.fetchUserBets(userId: userId)
            
            self.bets = userBets
            self.isLoading = false
            
            print("✅ Loaded \(userBets.count) bets for user")
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            print("❌ Error loading bets: \(error)")
        }
    }
    
    func cancelBet(_ bet: Bet) async {
        guard bet.status == .pending else {
            errorMessage = "Cannot cancel bet with status: \(bet.status)"
            return
        }
        
        do {
            let betRepository = BetRepository()
            
            var cancelledBet = bet
            cancelledBet.status = .cancelled
            
            try await betRepository.save(cancelledBet)
            
            // Update local list
            if let index = bets.firstIndex(where: { $0.id == bet.id }) {
                bets[index] = cancelledBet
            }
            
            print("✅ Cancelled bet: \(bet.id)")
            
        } catch {
            errorMessage = "Failed to cancel bet: \(error.localizedDescription)"
            print("❌ Error cancelling bet: \(error)")
        }
    }
}
