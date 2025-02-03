//
//  BetMatchingService.swift
//  BettorOdds
//
//  Created by Assistant on 2/2/25
//  Version: 1.0.1
//

import Foundation
import FirebaseFirestore

actor BetMatchingService {
    // MARK: - Properties
    static let shared = BetMatchingService()
    private let db = FirebaseConfig.shared.db  // Use FirebaseConfig instead of direct Firestore
    
    #if DEBUG
    var isTestMode = false  // Enable for automatic test matching
    #endif
    
    // MARK: - Public Methods
    
    /// Attempts to match a new bet with existing opposing bets
    /// - Parameter bet: The new bet to match
    /// - Returns: Updated bet with any matches
    func matchBet(_ bet: Bet) async throws -> Bet {
        print("🎲 Attempting to match bet: \(bet.id)")
        
        // 1. Find potential matches
        let opposingBets = try await findPotentialMatches(for: bet)
        
        // 2. Sort by FIFO (oldest first)
        let sortedBets = opposingBets.sorted { $0.createdAt < $1.createdAt }
        
        // 3. Try to match with each opposing bet
        var updatedBet = bet
        var remainingAmount = bet.amount
        
        for opposingBet in sortedBets {
            guard remainingAmount > 0 else { break }
            
            // Calculate match amount
            let matchAmount = min(remainingAmount, opposingBet.remainingAmount)
            
            // Create match
            let match = try await createMatch(
                betId: bet.id,
                opposingBetId: opposingBet.id,
                amount: Double(matchAmount)
            )
            
            // Update both bets
            try await updateBetsForMatch(
                bet: &updatedBet,
                opposingBet: opposingBet,
                match: match
            )
            
            remainingAmount -= matchAmount
        }
        
        // 4. Update bet status based on matching
        if remainingAmount == 0 {
            updatedBet.status = .fullyMatched
            try await updateBetStatus(betId: bet.id, newStatus: .fullyMatched)
        } else if remainingAmount < bet.amount {
            updatedBet.status = .partiallyMatched
            try await updateBetStatus(betId: bet.id, newStatus: .partiallyMatched)
        }
        
        return updatedBet
    }
    
    /// Cancels all pending bets for a game
    /// - Parameter gameId: The game's ID
    func cancelPendingBets(for gameId: String) async throws {
        print("🔄 Cancelling pending bets for game: \(gameId)")
        
        let pendingBets = try await db.collection("bets")
            .whereField("gameId", isEqualTo: gameId)
            .whereField("status", in: [BetStatus.pending.rawValue,
                                     BetStatus.partiallyMatched.rawValue])
            .getDocuments()
        
        for document in pendingBets.documents {
            guard let bet = Bet(document: document) else { continue }
            try await cancelBet(bet)
        }
    }
    
    /// Cancels a specific bet
    /// - Parameter bet: The bet to cancel
    func cancelBet(_ bet: Bet) async throws {
        guard bet.canBeCancelled else {
            throw BetError.cannotCancel
        }
        
        // Update status to cancelled
        try await updateBetStatus(betId: bet.id, newStatus: .cancelled)
        
        // Refund remaining amount
        if bet.remainingAmount > 0 {
            try await refundUser(
                userId: bet.userId,
                amount: bet.remainingAmount,
                coinType: bet.coinType
            )
        }
    }
    
    // MARK: - Private Methods
    
    // Make findPotentialMatches public and use FirebaseConfig
    func findPotentialMatches(for bet: Bet) async throws -> [Bet] {
        // Query for opposing bets on the same game
        let querySnapshot = try await FirebaseConfig.shared.db.collection("bets")
            .whereField("gameId", isEqualTo: bet.gameId)
            .whereField("status", in: [BetStatus.pending.rawValue,
                                     BetStatus.partiallyMatched.rawValue])
            .whereField("isHomeTeam", isEqualTo: !bet.isHomeTeam) // Opposite side
            .whereField("coinType", isEqualTo: bet.coinType.rawValue)
            .getDocuments()
        
        return querySnapshot.documents.compactMap { Bet(document: $0) }
    }
    
    private func createMatch(betId: String, opposingBetId: String, amount: Double) async throws -> BetMatch {
        let match = BetMatch(
            id: UUID().uuidString,
            betId: betId,
            matchedBetId: opposingBetId,
            amount: amount,
            createdAt: Date()
        )
        
        // Save match to Firestore
        try await db.collection("betMatches").document(match.id).setData(match.toDictionary())
        
        return match
    }
    
    private func updateBetsForMatch(bet: inout Bet, opposingBet: Bet, match: BetMatch) async throws {
        let batch = db.batch()
        
        // Update first bet
        let bet1Ref = db.collection("bets").document(bet.id)
        var bet1Data = bet.toDictionary()
        bet1Data["remainingAmount"] = bet.remainingAmount - Int(match.amount)
        bet1Data["matches"] = FieldValue.arrayUnion([match.toDictionary()])
        batch.updateData(bet1Data, forDocument: bet1Ref)
        
        // Update opposing bet
        let bet2Ref = db.collection("bets").document(opposingBet.id)
        var bet2Data = opposingBet.toDictionary()
        bet2Data["remainingAmount"] = opposingBet.remainingAmount - Int(match.amount)
        bet2Data["matches"] = FieldValue.arrayUnion([match.toDictionary()])
        batch.updateData(bet2Data, forDocument: bet2Ref)
        
        try await batch.commit()
    }
    
    private func updateBetStatus(betId: String, newStatus: BetStatus) async throws {
        try await db.collection("bets").document(betId).updateData([
            "status": newStatus.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    private func refundUser(userId: String, amount: Int, coinType: CoinType) async throws {
        // Implement refund logic using UserRepository
        let userRepo = UserRepository()
        try await userRepo.updateBalance(
            userId: userId,
            coinType: coinType,
            amount: amount
        )
    }
    
    // MARK: - Test Mode Methods
    
    #if DEBUG
    /// Simulates an opposing bet for testing
    func simulateOpposingBet(for bet: Bet) async throws {
        guard isTestMode else { return }
        
        // Create opposing bet
        let opposingBet = Bet(
            userId: "test_user",
            gameId: bet.gameId,
            coinType: bet.coinType,
            amount: bet.amount,
            initialSpread: -bet.initialSpread,  // Opposite spread
            team: bet.isHomeTeam ? bet.team : "Opposing Team",
            isHomeTeam: !bet.isHomeTeam  // Opposite side
        )
        
        // Save opposing test bet
        try await db.collection("bets").document(opposingBet.id).setData(opposingBet.toDictionary())
        
        // Attempt to match bets
        _ = try await matchBet(opposingBet)
    }
    
    /// Enables or disables test mode
    func setTestMode(_ enabled: Bool) {
        isTestMode = enabled
        print("🧪 Test mode \(enabled ? "enabled" : "disabled")")
    }
    #endif
    
    // MARK: - Error Handling
    
    enum BetError: Error {
        case insufficientBalance
        case gameIsLocked
        case invalidSpread
        case cannotCancel
        case matchingFailed
        
        var description: String {
            switch self {
            case .insufficientBalance:
                return "Insufficient balance to place bet"
            case .gameIsLocked:
                return "Game is locked for betting"
            case .invalidSpread:
                return "Spread has changed significantly"
            case .cannotCancel:
                return "Bet cannot be cancelled"
            case .matchingFailed:
                return "Failed to match bet"
            }
        }
    }
}
