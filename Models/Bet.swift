//
//  Bet.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.0
//

import SwiftUI
import Foundation
import FirebaseFirestore

// MARK: - Bet Status Enum
enum BetStatus: String, Codable {
    case pending = "Pending"   // Initial state when bet is placed
    case active = "Active"     // Bet has been matched
    case cancelled = "Cancelled" // Bet was cancelled (by user or system)
    case won = "Won"          // Bet was successful
    case lost = "Lost"        // Bet was unsuccessful
    
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .active:
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
    let amount: Int
    let initialSpread: Double
    let currentSpread: Double
    var status: BetStatus
    let createdAt: Date
    var updatedAt: Date
    let team: String  // Team bet on
    let isHomeTeam: Bool
    
    // MARK: - Computed Properties
    
    /// Calculates potential winnings based on bet amount
    var potentialWinnings: Int {
        // Standard -110 odds: Bet 110 to win 100
        return Int(Double(amount) * 0.909)
    }
    
    /// Checks if spread has changed enough to trigger cancellation
    var shouldCancelDueToSpreadChange: Bool {
        return abs(currentSpread - initialSpread) >= 1.0
    }
    
    /// Checks if bet can be cancelled (only pending bets)
    var canBeCancelled: Bool {
        return status == .pending
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
    }
    
    // MARK: - Firestore Conversion
    
    /// Initialize from Firestore document
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = document.documentID
        self.userId = data["userId"] as? String ?? ""
        self.gameId = data["gameId"] as? String ?? ""
        self.amount = data["amount"] as? Int ?? 0
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
    }
    
    /// Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "gameId": gameId,
            "coinType": coinType.rawValue,
            "amount": amount,
            "initialSpread": initialSpread,
            "currentSpread": currentSpread,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "team": team,
            "isHomeTeam": isHomeTeam
        ]
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
