//
//  TransactionRepository.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.1.0
//

import Foundation
import FirebaseFirestore

class TransactionRepository: Repository {
    // MARK: - Properties
    typealias T = Transaction
    
    let cacheFilename = "transactions.cache"
    let cacheExpiryTime: TimeInterval = 3600 // 1 hour
    
    private let transactionService: TransactionService
    
    // MARK: - Initialization
    init() {
        self.transactionService = TransactionService()
    }
    
    // MARK: - Repository Protocol Methods
    func fetch(id: String) async throws -> Transaction {
        guard let transaction = try? await transactionService.fetchTransaction(transactionId: id) else {
            throw RepositoryError.itemNotFound
        }
        return transaction
    }
    
    func save(_ transaction: Transaction) async throws {
        _ = try await transactionService.createTransaction(transaction)
    }
    
    func remove(id: String) async throws {
        // Transactions cannot be removed, only cancelled
        throw RepositoryError.operationNotSupported
    }
    
    func clearCache() throws {
        // Implementation for clearing cache
    }
    
    // MARK: - Additional Methods
    
    /// Fetches transactions for a user with optional filters
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - coinType: Optional filter for coin type
    ///   - type: Optional filter for transaction type
    /// - Returns: Array of transactions
    func fetchUserTransactions(
        userId: String,
        coinType: CoinType? = nil,
        type: TxType? = nil
    ) async throws -> [Transaction] {
        return try await transactionService.fetchUserTransactions(
            userId: userId,
            coinType: coinType,
            type: type
        )
    }
    
    /// Updates transaction status
    /// - Parameters:
    ///   - transactionId: The transaction's ID
    ///   - status: The new status
    func updateTransactionStatus(
        transactionId: String,
        status: TxStatus
    ) async throws {
        try await transactionService.updateTransactionStatus(
            transactionId: transactionId,
            status: status
        )
    }
    
    /// Calculates transaction statistics
    func calculateStats(from transactions: [Transaction]) -> TxStats {
        var stats = TxStats()
        
        for transaction in transactions {
            switch transaction.type {
            case .deposit:
                stats.totalDeposits += transaction.amount
            case .withdrawal:
                stats.totalWithdrawals += transaction.amount
            case .bet:
                stats.totalBets += 1
                stats.totalWagered += abs(transaction.amount)
            case .win:
                stats.totalWins += 1
                stats.totalWon += transaction.amount
            case .loss:
                stats.totalLosses += 1
            case .refund:
                stats.totalRefunds += transaction.amount
            }
        }
        
        return stats
    }
}
