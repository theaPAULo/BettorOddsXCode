//
//  DatabaseError.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/28/25.
//


import Foundation

/// Common errors for database operations
enum DatabaseError: Error {
    case documentNotFound
    case insufficientFunds
    case dailyLimitExceeded
    case invalidData
    case transactionFailed
    case networkError
    case authenticationRequired
    
    var localizedDescription: String {
        switch self {
        case .documentNotFound:
            return "The requested document was not found"
        case .insufficientFunds:
            return "Insufficient funds for this transaction"
        case .dailyLimitExceeded:
            return "Daily betting limit exceeded"
        case .invalidData:
            return "The data is invalid or corrupted"
        case .transactionFailed:
            return "The transaction failed to complete"
        case .networkError:
            return "Network error occurred"
        case .authenticationRequired:
            return "Authentication is required for this operation"
        }
    }
}