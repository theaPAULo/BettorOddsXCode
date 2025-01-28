//
//  TransactionService.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/28/25.
//  Version: 1.0.0
//

import Foundation
import FirebaseFirestore

actor TransactionService {
    // MARK: - Properties
    private let db = FirebaseConfig.shared.db
    
    // MARK: - CRUD Operations
    
    /// Creates a new transaction
    /// - Parameter transaction: The transaction to create
    /// - Returns: The created transaction
    func createTransaction(_ transaction: Transaction) async throws -> Transaction {
        let ref = db.collection("transactions").document()
        var newTransaction = transaction
        
        try await ref.setData(newTransaction.toDictionary())
        return newTransaction
    }
    
    /// Fetches a specific transaction
    /// - Parameter transactionId: The ID of the transaction to fetch
    /// - Returns: The fetched transaction
    func fetchTransaction(transactionId: String) async throws -> Transaction {
        let document = try await db.collection("transactions").document(transactionId).getDocument()
        
        guard let transaction = Transaction(document: document) else {
            throw DatabaseError.documentNotFound
        }
        
        return transaction
    }
    
    /// Fetches all transactions for a user
    /// - Parameters:
    ///   - userId: The ID of the user
    ///   - coinType: Optional filter for coin type
    ///   - type: Optional filter for transaction type
    /// - Returns: Array of transactions
    func fetchUserTransactions(
        userId: String,
        coinType: CoinType? = nil,
        type: TxType? = nil
    ) async throws -> [Transaction] {
        var query = db.collection("transactions")
            .whereField("userId", isEqualTo: userId)
        
        // Apply filters if provided
        if let coinType = coinType {
            query = query.whereField("coinType", isEqualTo: coinType.rawValue)
        }
        
        if let type = type {
            query = query.whereField("type", isEqualTo: type.rawValue)
        }
        
        // Execute query
        let snapshot = try await query
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { Transaction(document: $0) }
    }
    
    /// Updates transaction status
    /// - Parameters:
    ///   - transactionId: The ID of the transaction
    ///   - status: The new status
    func updateTransactionStatus(
        transactionId: String,
        status: TxStatus
    ) async throws {
        let ref = db.collection("transactions").document(transactionId)
        
        try await ref.updateData([
            "status": status.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Aggregation Methods
    
    /// Calculates total transaction amount for a user within a date range
    /// - Parameters:
    ///   - userId: The ID of the user
    ///   - coinType: The type of coin to calculate
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    /// - Returns: Total amount
    func calculateTotal(
        userId: String,
        coinType: CoinType,
        startDate: Date,
        endDate: Date
    ) async throws -> Double {
        let snapshot = try await db.collection("transactions")
            .whereField("userId", isEqualTo: userId)
            .whereField("coinType", isEqualTo: coinType.rawValue)
            .whereField("createdAt", isGreaterThanOrEqualTo: startDate)
            .whereField("createdAt", isLessThanOrEqualTo: endDate)
            .whereField("status", isEqualTo: TxStatus.completed.rawValue)
            .getDocuments()
        
        return snapshot.documents
            .compactMap { Transaction(document: $0) }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Fetches transaction statistics for a user
    /// - Parameters:
    ///   - userId: The ID of the user
    ///   - coinType: The type of coin
    /// - Returns: Transaction statistics
    func fetchTransactionStats(
        userId: String,
        coinType: CoinType
    ) async throws -> TxStats {
        let transactions = try await fetchUserTransactions(
            userId: userId,
            coinType: coinType
        )
        
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
