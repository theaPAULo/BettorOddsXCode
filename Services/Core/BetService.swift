import Foundation
import FirebaseFirestore

actor BetService {
    // MARK: - Properties
    private let db = FirebaseConfig.shared.db
    private let userService = UserService()
    private let transactionService = TransactionService()
    
    // MARK: - CRUD Operations
    
    /// Places a new bet
    /// - Parameter bet: The bet to place
    /// - Returns: The created bet
    func placeBet(_ bet: Bet) async throws -> Bet {
        // Start a batch write
        let batch = db.batch()
        
        // 1. Create bet document reference
        let betRef = db.collection("bets").document()
        
        // Create a new bet with the document ID
        let newBet = Bet(
            id: betRef.documentID,
            userId: bet.userId,
            gameId: bet.gameId,
            coinType: bet.coinType,
            amount: bet.amount,
            initialSpread: bet.initialSpread,
            team: bet.team,
            isHomeTeam: bet.isHomeTeam
        )
        
        // 2. Validate and update user balance
        try await validateAndUpdateBalance(for: newBet)
        
        // 3. Create transaction for the bet
        let transaction = Transaction(
            userId: bet.userId,
            type: .bet,
            coinType: bet.coinType,
            amount: -Double(bet.amount),
            betId: newBet.id,
            description: "Bet placed on \(bet.team)"
        )
        
        // 4. Add documents to batch
        batch.setData(newBet.toDictionary(), forDocument: betRef)
        
        // 5. Execute batch
        try await batch.commit()
        
        // 6. Create transaction (done separately to ensure bet is placed)
        try await transactionService.createTransaction(transaction)
        
        return newBet
    }
    
    /// Fetches a specific bet
    /// - Parameter betId: The ID of the bet to fetch
    /// - Returns: The fetched bet
    func fetchBet(betId: String) async throws -> Bet {
        let document = try await db.collection("bets").document(betId).getDocument()
        
        guard let bet = Bet(document: document) else {
            throw DatabaseError.documentNotFound
        }
        
        return bet
    }
    
    /// Fetches all bets for a user
    /// - Parameter userId: The ID of the user
    /// - Returns: Array of bets
    func fetchUserBets(userId: String) async throws -> [Bet] {
        let snapshot = try await db.collection("bets")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { Bet(document: $0) }
    }
    
    /// Cancels a bet
    /// - Parameter betId: The ID of the bet to cancel
    func cancelBet(_ betId: String) async throws {
        let betRef = db.collection("bets").document(betId)
        
        return try await withCheckedThrowingContinuation { continuation in
            // Use Firebase's transaction method
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    // 1. Get current bet
                    let betDocument = try transaction.getDocument(betRef)
                    guard var existingBet = Bet(document: betDocument) else {
                        throw DatabaseError.documentNotFound
                    }
                    
                    // 2. Validate bet can be cancelled
                    guard existingBet.canBeCancelled else {
                        throw BetError.cannotCancel
                    }
                    
                    // Update bet in Firestore with cancelled status
                    transaction.updateData(
                        ["status": BetStatus.cancelled.rawValue,
                         "updatedAt": Timestamp(date: Date())],
                        forDocument: betRef
                    )
                    
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }, completion: { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    // Perform refund outside of the transaction
                    Task {
                        do {
                            try await self.refundBet(betId)
                            continuation.resume(returning: ())
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            })
        }
    }
    
    /// Updates bet status and processes winnings if applicable
    /// - Parameters:
    ///   - betId: The ID of the bet to update
    ///   - status: The new status
    func updateBetStatus(betId: String, status: BetStatus) async throws {
        let betRef = db.collection("bets").document(betId)
        
        return try await withCheckedThrowingContinuation { continuation in
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    // 1. Get current bet
                    let betDocument = try transaction.getDocument(betRef)
                    guard let existingBet = Bet(document: betDocument) else {
                        throw DatabaseError.documentNotFound
                    }
                    
                    // 2. Update status in Firestore
                    transaction.updateData(
                        ["status": status.rawValue,
                         "updatedAt": Timestamp(date: Date())],
                        forDocument: betRef
                    )
                    
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }, completion: { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    // Process winnings if needed
                    Task {
                        do {
                            if status == .won {
                                try await self.processBetWinningsForBet(betId)
                            }
                            continuation.resume(returning: ())
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            })
        }
    }
    
    // MARK: - Helper Methods
    
    /// Validates bet and updates user balance
    private func validateAndUpdateBalance(for bet: Bet) async throws {
        // 1. Validate bet amount
        guard Bet.validateBetAmount(bet.amount, coinType: bet.coinType) else {
            throw BetError.invalidAmount
        }
        
        // 2. For green coins, check daily limit
        if bet.coinType == .green {
            try await userService.updateDailyGreenCoinsUsage(
                userId: bet.userId,
                amount: bet.amount
            )
        }
        
        // 3. Update user balance
        try await userService.updateBalance(
            userId: bet.userId,
            coinType: bet.coinType,
            amount: -bet.amount
        )
    }
    
    /// Processes winnings for a winning bet by fetching the bet first
    private func processBetWinningsForBet(_ betId: String) async throws {
        // Fetch the bet first
        let bet = try await fetchBet(betId: betId)
        
        // Calculate winnings
        let winnings = bet.potentialWinnings
        
        // Create transaction for winnings
        let transaction = Transaction(
            userId: bet.userId,
            type: .win,
            coinType: bet.coinType,
            amount: Double(winnings),
            betId: bet.id,
            description: "Won bet on \(bet.team)"
        )
        
        // Update user balance and create transaction
        try await userService.updateBalance(
            userId: bet.userId,
            coinType: bet.coinType,
            amount: winnings
        )
        
        try await transactionService.createTransaction(transaction)
    }
    
    /// Refunds a cancelled bet by fetching the bet first
    private func refundBet(_ betId: String) async throws {
        // Fetch the bet first
        let bet = try await fetchBet(betId: betId)
        
        // Create refund transaction
        let transaction = Transaction(
            userId: bet.userId,
            type: .refund,
            coinType: bet.coinType,
            amount: Double(bet.amount),
            betId: bet.id,
            description: "Refund for cancelled bet"
        )
        
        // Update user balance
        try await userService.updateBalance(
            userId: bet.userId,
            coinType: bet.coinType,
            amount: bet.amount
        )
        
        // If it was a green coin bet, update daily usage
        if bet.coinType == .green {
            try await userService.updateDailyGreenCoinsUsage(
                userId: bet.userId,
                amount: -bet.amount
            )
        }
        
        try await transactionService.createTransaction(transaction)
    }
}

// MARK: - Errors
enum BetError: Error {
    case invalidAmount
    case insufficientFunds
    case dailyLimitExceeded
    case cannotCancel
    case alreadyProcessed
    
    var localizedDescription: String {
        switch self {
        case .invalidAmount:
            return "Invalid bet amount"
        case .insufficientFunds:
            return "Insufficient funds for this bet"
        case .dailyLimitExceeded:
            return "Daily betting limit exceeded"
        case .cannotCancel:
            return "This bet cannot be cancelled"
        case .alreadyProcessed:
            return "This bet has already been processed"
        }
    }
}
