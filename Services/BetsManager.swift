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

@MainActor
class BetsManager: ObservableObject {
    // MARK: - Singleton
    static let shared = BetsManager()
    
    // MARK: - Published Properties
    @Published private(set) var bets: [Bet] = []
    @Published private(set) var isLoading = false
    
    // MARK: - Error Handling
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
                return "Failed to connect to server"
            case .dailyLimitExceeded:
                return "Daily betting limit exceeded"
            case .insufficientFunds:
                return "Insufficient funds"
            }
        }
    }
    
    // MARK: - Private Init for Singleton
    private init() {}
    
    // MARK: - Public Methods
    func placeBet(_ bet: Bet) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Replace with actual API call
        // For now, simulate network request
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Validate bet
        guard validateBet(bet) else {
            throw BetsError.invalidBet
        }
        
        // Add to local array
        bets.append(bet)
        
        // Simulate successful API response
        return
    }
    
    func fetchBets() async throws -> [Bet] {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Replace with actual API call
        // For now, simulate network request
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return bets
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
