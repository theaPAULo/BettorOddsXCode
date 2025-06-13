//
//  EnhancedViewModelSupport.swift
//  BettorOdds
//
//  Created by Claude on 6/13/25
//  Version: 1.0.1 - Fixed compilation condition error
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Configuration Alias

// Swift alias for Configuration -> AppConfiguration
typealias AppConfiguration = Configuration

// MARK: - Transaction Models for Enhanced ViewModels

struct BetTransaction: Identifiable, Codable {
    let id: String
    let userId: String
    let type: BetTransactionType
    let coinType: CoinType
    let amount: Double
    let createdAt: Date
    let relatedBetId: String?
    let relatedGameId: String?
    let description: String
    let status: BetTransactionStatus
    
    init(id: String = UUID().uuidString,
         userId: String,
         type: BetTransactionType,
         coinType: CoinType,
         amount: Double,
         relatedBetId: String? = nil,
         relatedGameId: String? = nil,
         description: String? = nil,
         status: BetTransactionStatus = .completed) {
        self.id = id
        self.userId = userId
        self.type = type
        self.coinType = coinType
        self.amount = amount
        self.createdAt = Date()
        self.relatedBetId = relatedBetId
        self.relatedGameId = relatedGameId
        self.description = description ?? type.defaultDescription
        self.status = status
    }
}

enum BetTransactionType: String, Codable, CaseIterable {
    case bet = "bet"
    case win = "win"
    case refund = "refund"
    case deposit = "deposit"
    case withdrawal = "withdrawal"
    case bonus = "bonus"
    case adjustment = "adjustment"
    
    var defaultDescription: String {
        switch self {
        case .bet: return "Bet placed"
        case .win: return "Bet won"
        case .refund: return "Bet refunded"
        case .deposit: return "Coins deposited"
        case .withdrawal: return "Coins withdrawn"
        case .bonus: return "Bonus awarded"
        case .adjustment: return "Balance adjustment"
        }
    }
}

enum BetTransactionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}

// MARK: - Enhanced Repository Wrappers (New methods, no conflicts)

extension BetRepository {
    /// Enhanced save method for new ViewModels
    func saveBetEnhanced(_ bet: Bet) async throws {
        try await self.save(bet)
    }
    
    /// Enhanced delete method for new ViewModels
    func deleteBetEnhanced(_ betId: String) async throws {
        try await self.remove(id: betId)
    }
}

extension UserRepository {
    /// Enhanced fetch with Result return type
    func fetchUserWithResult(userId: String) async -> Result<User, AppError> {
        do {
            if let user = try await self.fetch(id: userId) {
                return .success(user)
            } else {
                return .failure(.userNotFound)
            }
        } catch {
            return .failure(.firestoreEnhanced(error))
        }
    }
    
    /// Enhanced update with Result return type
    func updateUserWithResult(_ user: User) async -> Result<Void, AppError> {
        do {
            try await self.save(user)
            return .success(())
        } catch {
            return .failure(.firestoreEnhanced(error))
        }
    }
    
    /// Enhanced create with Result return type
    func createUserWithResult(_ user: User) async -> Result<User, AppError> {
        do {
            try await self.save(user)
            return .success(user)
        } catch {
            return .failure(.firestoreEnhanced(error))
        }
    }
}

// MARK: - AppError Extensions (enhanced versions to avoid conflicts)

extension AppError {
    /// Creates an AppError from a Firebase Auth error (enhanced version)
    static func firebaseAuthEnhanced(_ error: Error) -> AppError {
        return .authenticationFailed(error.localizedDescription)
    }
    
    /// Creates an AppError from a Firestore error (enhanced version)
    static func firestoreEnhanced(_ error: Error) -> AppError {
        if error.localizedDescription.contains("permission") {
            return .permissionDenied
        } else if error.localizedDescription.contains("not found") {
            return .documentNotFound
        } else {
            return .databaseError(error.localizedDescription)
        }
    }
}
