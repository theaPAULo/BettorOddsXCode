//
//  BetModalViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 2.3.0

import SwiftUI

class BetModalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedCoinType: CoinType = .yellow
    @Published var betAmount: String = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let game: Game
    private let user: User
    
    // MARK: - Computed Properties
    var remainingDailyLimit: Int {
        100 - (user.dailyGreenCoinsUsed)
    }
    
    var potentialWinnings: Int {
        guard let amount = Int(betAmount) else { return 0 }
        // 1:1 odds - win same amount as bet
        return amount
    }
    
    // MARK: - Initialization
    init(game: Game, user: User) {
        self.game = game
        self.user = user
    }
    
    // MARK: - Public Methods
    func placeBet(team: String, isHomeTeam: Bool) async throws -> Bool {
        guard let amount = Int(betAmount) else {
            throw BetError.invalidAmount
        }
        
        // Validate bet amount
        if selectedCoinType == .green {
            guard amount <= remainingDailyLimit else {
                throw BetError.dailyLimitExceeded
            }
            guard amount <= user.greenCoins else {
                throw BetError.insufficientFunds
            }
        } else {
            guard amount <= user.yellowCoins else {
                throw BetError.insufficientFunds
            }
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let bet = Bet(
            userId: user.id,
            gameId: game.id,
            coinType: selectedCoinType,
            amount: amount,
            initialSpread: isHomeTeam ? game.spread : -game.spread,
            team: team,
            isHomeTeam: isHomeTeam
        )
        
        // TODO: Make actual API call to place bet
        // For now, simulate success
        return true
    }
}

// MARK: - Error Types
enum BetError: Error {
    case invalidAmount
    case insufficientFunds
    case dailyLimitExceeded
    case networkError
    
    var message: String {
        switch self {
        case .invalidAmount:
            return "Please enter a valid bet amount"
        case .insufficientFunds:
            return "Insufficient funds for this bet"
        case .dailyLimitExceeded:
            return "Daily betting limit exceeded"
        case .networkError:
            return "Network error. Please try again"
        }
    }
}
