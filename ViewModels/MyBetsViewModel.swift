//
//  MyBetsViewModel.swift
//  BettorOdds
//
//  Version: 1.0.0 - Created to support MyBetsView
//  Updated: June 2025
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class MyBetsViewModel: ListViewModel<Bet> {
    
    // MARK: - Published Properties
    @Published var totalBets: Int = 0
    @Published var wonBets: Int = 0
    @Published var lostBets: Int = 0
    @Published var pendingBets: Int = 0
    @Published var winRate: Int = 0
    
    // MARK: - Private Properties
    private let betRepository = BetRepository()
    
    // MARK: - Computed Properties
    
    var bets: [Bet] {
        return items
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Loads bets for the current user
    override func loadItems() async {
        await loadBets()
    }
    
    /// Loads all bets for the current user
    func loadBets() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user")
            return
        }
        
        await executeAsync({
            let userBets = try await self.betRepository.fetchBets(userId: userId)
            return userBets
        }, onSuccess: { [weak self] (bets: [Bet]) in
            self?.items = bets
            self?.updateStats()
            print("✅ Loaded \(bets.count) bets for user")
        }, onError: { [weak self] error in
            print("❌ Error loading bets: \(error)")
            self?.handleError(AppError.databaseError(error.localizedDescription))
        })
    }
    
    /// Cancels a pending bet
    func cancelBet(_ bet: Bet) async {
        guard bet.status == .pending else {
            print("❌ Cannot cancel bet with status: \(bet.status)")
            return
        }
        
        await executeAsync({
            // Update bet status to cancelled
            var cancelledBet = bet
            cancelledBet.status = .cancelled
            
            try await self.betRepository.save(cancelledBet)
            
            // Note: In a real app, you'd also need to refund the user's coins
            // For now, we'll just update the bet status
            
            return cancelledBet
        }, onSuccess: { [weak self] (cancelledBet: Bet) in
            // Update the bet in our local list
            if let index = self?.items.firstIndex(where: { $0.id == cancelledBet.id }) {
                self?.items[index] = cancelledBet
                self?.updateStats()
                print("✅ Cancelled bet: \(cancelledBet.id)")
            }
        }, onError: { [weak self] error in
            print("❌ Error cancelling bet: \(error)")
            self?.handleError(AppError.betCancellationFailed)
        })
    }
    
    // MARK: - Private Methods
    
    /// Updates betting statistics
    private func updateStats() {
        totalBets = items.count
        wonBets = items.filter { $0.status == .won }.count
        lostBets = items.filter { $0.status == .lost }.count
        pendingBets = items.filter { $0.status == .pending || $0.status == .active }.count
        
        // Calculate win rate
        let completedBets = wonBets + lostBets
        if completedBets > 0 {
            winRate = Int(Double(wonBets) / Double(completedBets) * 100)
        } else {
            winRate = 0
        }
        
        print("📊 Updated stats: \(totalBets) total, \(wonBets) won, \(lostBets) lost, \(pendingBets) pending, \(winRate)% win rate")
    }
}