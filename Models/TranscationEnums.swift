//
//  TransactionEnums.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/28/25.
//  Version: 1.0.0
//

import Foundation

/// Namespace for transaction-related types to avoid ambiguity
enum TransactionModels {
    /// Different types of transactions in the app
    enum TransactionType: String, Codable, CaseIterable {
        case deposit    // Adding funds
        case withdrawal // Removing funds
        case bet       // Placing a bet
        case win       // Winning a bet
        case loss      // Losing a bet
        case refund    // Refunding a bet
    }

    /// Status of a transaction
    enum TransactionStatus: String, Codable {
        case pending    // Transaction is being processed
        case completed  // Transaction has been completed
        case failed    // Transaction failed to process
        case cancelled // Transaction was cancelled
    }

    /// Statistics for transaction analysis
    struct TransactionStats {
        var totalDeposits: Double = 0
        var totalWithdrawals: Double = 0
        var totalBets: Int = 0
        var totalWagered: Double = 0
        var totalWins: Int = 0
        var totalWon: Double = 0
        var totalLosses: Int = 0
        var totalRefunds: Double = 0
        
        var netProfit: Double {
            return totalWon - totalWagered + totalRefunds
        }
        
        var winRate: Double {
            guard totalBets > 0 else { return 0 }
            return Double(totalWins) / Double(totalBets) * 100
        }
    }
}

/// Type aliases for convenience
typealias TxType = TransactionModels.TransactionType
typealias TxStatus = TransactionModels.TransactionStatus
typealias TxStats = TransactionModels.TransactionStats
