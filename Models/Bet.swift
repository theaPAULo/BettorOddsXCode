//
//  Bet.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 2.0.0 - Added P2P support
//

import SwiftUI
import FirebaseFirestore
import Foundation

// MARK: - Bet Match Model
struct BetMatch: Identifiable, Codable {
    let id: String
    let betId: String           // Original bet ID
    let matchedBetId: String    // Opposing bet ID
    let amount: Double          // Amount matched between these two bets
    let createdAt: Date
    
    // Convert to Firestore data
    func toDictionary() -> [String: Any] {
        return [
            "betId": betId,
            "matchedBetId": matchedBetId,
            "amount": amount,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

// MARK: - Bet Status Enum
enum BetStatus: String, Codable, CaseIterable {
    case pending = "Pending"         // Initial state when bet is placed, waiting for match
    case partiallyMatched = "Partially Matched" // Some portion matched, some still pending
    case fullyMatched = "Matched"    // Completely matched with opposing bet(s)
    case active = "Active"           // Match complete, game in progress
    case cancelled = "Cancelled"     // Bet was cancelled (by user, spread change, or game lock)
    case won = "Won"                 // Bet was successful
    case lost = "Lost"               // Bet was unsuccessful
    
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .partiallyMatched:
            return .yellow
        case .fullyMatched, .active:
            return .blue
        case .cancelled:
            return .gray
        case .won:
            return .green
        case .lost:
            return .red
        }
    }
}

// MARK: - Bet Model
struct Bet: Identifiable, Codable {
    let id: String
    let userId: String
    let gameId: String
    let coinType: CoinType
    let amount: Int               // Total bet amount
    let initialSpread: Double
    let currentSpread: Double
    var status: BetStatus
    let createdAt: Date
    var updatedAt: Date
    let team: String             // Team bet on
    let isHomeTeam: Bool
    var matches: [BetMatch]      // Array of matches for this bet
    var remainingAmount: Int     // Amount still needing to be matched
    
    // MARK: - Computed Properties
    
    /// Amount of this bet that has been matched
    var matchedAmount: Int {
        matches.reduce(0) { $0 + Int($1.amount) }
    }
    
    /// Calculates potential winnings based on bet amount
    var potentialWinnings: Int {
        // Even odds: Bet 100 to win 100
        return amount
    }
    
    /// Checks if spread has changed enough to trigger cancellation
    var spreadHasChangedSignificantly: Bool {
        return abs(currentSpread - initialSpread) >= 1.0
    }
    
    /// Checks if bet can be cancelled (only pending or partially matched bets)
    var canBeCancelled: Bool {
        return status == .pending || status == .partiallyMatched
    }
    
    // MARK: - Initialization
    init(id: String = UUID().uuidString,
         userId: String,
         gameId: String,
         coinType: CoinType,
         amount: Int,
         initialSpread: Double,
         team: String,
         isHomeTeam: Bool) {
        self.id = id
        self.userId = userId
        self.gameId = gameId
        self.coinType = coinType
        self.amount = amount
        self.initialSpread = initialSpread
        self.currentSpread = initialSpread
        self.status = .pending
        self.createdAt = Date()
        self.updatedAt = Date()
        self.team = team
        self.isHomeTeam = isHomeTeam
        self.matches = []
        self.remainingAmount = amount  // Initially, all amount needs matching
    }
    
    // MARK: - Firestore Conversion
    
    /// Initialize from Firestore document
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = document.documentID
        self.userId = data["userId"] as? String ?? ""
        self.gameId = data["gameId"] as? String ?? ""
        self.amount = data["amount"] as? Int ?? 0
        self.remainingAmount = data["remainingAmount"] as? Int ?? 0
        self.initialSpread = data["initialSpread"] as? Double ?? 0.0
        self.currentSpread = data["currentSpread"] as? Double ?? 0.0
        self.team = data["team"] as? String ?? ""
        self.isHomeTeam = data["isHomeTeam"] as? Bool ?? false
        
        // Handle complex types
        if let coinTypeString = data["coinType"] as? String,
           let coinType = CoinType(rawValue: coinTypeString) {
            self.coinType = coinType
        } else {
            return nil
        }
        
        if let statusString = data["status"] as? String,
           let status = BetStatus(rawValue: statusString) {
            self.status = status
        } else {
            return nil
        }
        
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        
        // Load matches if they exist
        if let matchesData = data["matches"] as? [[String: Any]] {
            self.matches = matchesData.compactMap { matchData in
                guard let id = matchData["id"] as? String,
                      let betId = matchData["betId"] as? String,
                      let matchedBetId = matchData["matchedBetId"] as? String,
                      let amount = matchData["amount"] as? Double,
                      let createdAt = (matchData["createdAt"] as? Timestamp)?.dateValue()
                else {
                    return nil
                }
                return BetMatch(id: id, betId: betId, matchedBetId: matchedBetId,
                              amount: amount, createdAt: createdAt)
            }
        } else {
            self.matches = []
        }
    }
    
    /// Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "gameId": gameId,
            "coinType": coinType.rawValue,
            "amount": amount,
            "remainingAmount": remainingAmount,
            "initialSpread": initialSpread,
            "currentSpread": currentSpread,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "team": team,
            "isHomeTeam": isHomeTeam
        ]
        
        // Add matches if they exist
        if !matches.isEmpty {
            dict["matches"] = matches.map { $0.toDictionary() }
        }
        
        return dict
    }
    
    // MARK: - Validation
    
    /// Validates bet amount against rules
    static func validateBetAmount(_ amount: Int, coinType: CoinType, userDailyGreenCoinsUsed: Int = 0) -> Bool {
        // Check minimum bet
        guard amount >= 1 else { return false }
        
        // Check maximum bet
        guard amount <= 100 else { return false }
        
        // For green coins, check daily limit
        if coinType == .green {
            let totalAfterBet = userDailyGreenCoinsUsed + amount
            guard totalAfterBet <= 100 else { return false }
        }
        
        return true
    }
}
