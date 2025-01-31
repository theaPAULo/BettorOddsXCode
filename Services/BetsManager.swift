//
//  BetsManager.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//


//
//  BetsManager.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.0.0
//

import Foundation
import Combine
import Firebase
import FirebaseAuth

enum BetsError: Error {
    case invalidBet
    case networkError
    case dailyLimitExceeded
    case insufficientFunds
    
    var localizedDescription: String {
        switch self {
        case .invalidBet:
            return "Invalid bet parameters"
        case .networkError:
            return "Network connection error. Please try again."
        case .dailyLimitExceeded:
            return "Daily betting limit exceeded"
        case .insufficientFunds:
            return "Insufficient funds"
        }
    }
}

@MainActor
class BetsManager: ObservableObject {
    static let shared = BetsManager()
    @Published private(set) var bets: [Bet] = []
    @Published private(set) var isLoading = false
    
    private let db = Firestore.firestore()
    
    func placeBet(_ bet: Bet) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("📝 Attempting to save bet to Firestore...")
            let data = bet.toDictionary()
            try await db.collection("bets").document(bet.id).setData(data)
            bets.append(bet)
            print("✅ Bet saved to Firestore with ID: \(bet.id)")
        } catch let error as NSError {
            print("❌ Error saving bet: \(error.localizedDescription)")
            if error.domain == NSURLErrorDomain {
                throw BetsError.networkError
            }
            throw error
        }
    }
    
    func fetchBets() async throws -> [Bet] {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user logged in")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        // Add this right after getting currentUser?.uid
        print("🔑 Query userId: \(userId)")
        print("🔑 Expected userId from Firestore: hDr6MObDmAQRxB1o44E5EQp0ozw1")
        print("🔑 Do they match? \(userId == "hDr6MObDmAQRxB1o44E5EQp0ozw1")")
        print("🔑 Current userId for fetching: \(userId)")
        
        do {
            print("📝 Starting Firestore query...")
            let query = db.collection("bets")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
            
            print("🔍 Executing query: \(query)")
            let snapshot = try await query.getDocuments()
            
            print("📄 Got \(snapshot.documents.count) documents")
            
            let bets = snapshot.documents.compactMap { document -> Bet? in
                print("Processing document ID: \(document.documentID)")
                print("Document data: \(document.data())")
                return Bet(document: document)
            }
            
            print("✅ Successfully parsed \(bets.count) bets")
            return bets
            
        } catch let error as NSError {
            print("❌ Detailed error: \(error)")
            print("❌ Error domain: \(error.domain)")
            print("❌ Error code: \(error.code)")
            throw error
        }
    }
    
    func cancelBet(_ betId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Replace with actual API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        if let index = bets.firstIndex(where: { $0.id == betId }) {
            var cancelledBet = bets[index]
            cancelledBet.status = .cancelled
            bets[index] = cancelledBet
        }
    }
    
    // MARK: - Private Methods
    private func validateBet(_ bet: Bet) -> Bool {
        // Check if bet amount is valid
        guard bet.amount > 0 && bet.amount <= 100 else {
            return false
        }
        
        // For green coins, check daily limit
        if bet.coinType == .green {
            let dailyTotal = bets
                .filter { $0.coinType == .green && Calendar.current.isDateInToday($0.createdAt) }
                .reduce(0) { $0 + $1.amount }
            
            guard (dailyTotal + bet.amount) <= 100 else {
                return false
            }
        }
        
        return true
    }
}
