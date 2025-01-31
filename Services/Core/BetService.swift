import Foundation
import FirebaseFirestore

class BetService {
    private let db = Firestore.firestore()
    
    func fetchBet(betId: String) async throws -> Bet {
        let doc = try await db.collection("bets").document(betId).getDocument()
        
        guard let bet = Bet(document: doc) else {
            throw RepositoryError.itemNotFound
        }
        
        return bet
    }
    
    func fetchUserBets(userId: String) async throws -> [Bet] {
        let snapshot = try await db.collection("bets")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { Bet(document: $0) }
    }
    
    func placeBet(_ bet: Bet) async throws -> Bet {
        let data = bet.toDictionary()
        try await db.collection("bets").document(bet.id).setData(data)
        return bet
    }
    
    func cancelBet(_ betId: String) async throws {
        let bet = try await fetchBet(betId: betId)
        guard bet.canBeCancelled else {
            throw RepositoryError.operationNotSupported
        }
        
        try await db.collection("bets").document(betId).updateData([
            "status": BetStatus.cancelled.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    func updateBetStatus(betId: String, status: BetStatus) async throws {
        let bet = try await fetchBet(betId: betId)
        guard bet.coinType == .green else {
            throw RepositoryError.operationNotSupported
        }
        
        try await db.collection("bets").document(betId).updateData([
            "status": status.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])
    }
}
