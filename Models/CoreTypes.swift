//
//  CoreTypes.swift
//  BettorOdds
//
//  Created by Claude on 6/13/25
//  Version: 1.0.0 - Only missing types that don't conflict with existing code
//

import Foundation
import SwiftUI

// MARK: - Repository Factory Extensions (for enhanced ViewModels)

extension BetRepository {
    /// Wrapper for save method that works with our enhanced error handling
    func saveBet(_ bet: Bet) async throws {
        try await self.save(bet)
    }
    
    /// Wrapper for fetch method that works with our enhanced error handling
    func fetchBet(id: String) async throws -> Bet? {
        return try await self.fetch(id: id)
    }
}
    
    extension UserRepository {
        /// Wrapper methods for enhanced ViewModels compatibility
        func fetchUser(userId: String) async -> Result<User, AppError> {
            do {
                if let user = try await self.fetch(id: userId) {
                    return .success(user)
                } else {
                    return .failure(.userNotFound)
                }
            } catch {
                return .failure(.firestore(error))
            }
        }
        
        func updateUser(_ user: User) async -> Result<Void, AppError> {
            do {
                try await self.save(user)
                return .success(())
            } catch {
                return .failure(.firestore(error))
            }
        }
        
        func createUser(_ user: User) async -> Result<User, AppError> {
            do {
                try await self.save(user)
                return .success(user)
            } catch {
                return .failure(.firestore(error))
            }
        }
    }
    
    extension TransactionRepository {
        /// Wrapper for transaction creation
        func saveTransaction(_ transaction: Transaction) async throws {
            try await self.save(transaction)
        }
    }
    
    // MARK: - Configuration Aliases (for easier migration)
    
    /// Convenience typealias for Configuration access
    typealias AppConfiguration = Configuration
    
    // MARK: - Result Extensions
    
    extension Result where Failure == Error {
        /// Converts a standard Result to AppError Result
        func toAppError() -> Result<Success, AppError> {
            return self.mapError { error in
                if let appError = error as? AppError {
                    return appError
                } else {
                    return AppError.unknown(error.localizedDescription)
                }
            }
        }
    }
