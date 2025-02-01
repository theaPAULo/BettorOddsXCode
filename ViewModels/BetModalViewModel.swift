//
//  BetModalViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.0.0
//

import SwiftUI

@MainActor
class BetModalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedCoinType: CoinType = .yellow
    @Published var betAmount: String = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let game: Game
    private let user: User
    private let betRepository: BetRepository
    private let userRepository: UserRepository
    
    // MARK: - Computed Properties
    var canPlaceBet: Bool {
        guard let amount = Int(betAmount), amount > 0 else {
            return false
        }
            
        // Check if game is locked
        if game.isLocked {
            return false
        }
            
        if selectedCoinType == .green {
            // Check daily limit for green coins
            return amount <= remainingDailyLimit && amount <= user.greenCoins
        }
            
        // For yellow coins, just check if user has enough
        return amount <= user.yellowCoins
    }
    
    var remainingDailyLimit: Int {
        return user.remainingDailyGreenCoins
    }
    
    var potentialWinnings: String {
        guard let amount = Double(betAmount) else { return "0" }
        // Even odds: Bet amount equals winning amount
        return String(format: "%.0f", amount)
    }
    
    // MARK: - Initialization
    init(game: Game, user: User) {
        self.game = game
        self.user = user
        
        // Initialize repositories
        do {
            self.betRepository = try BetRepository()
            self.userRepository = try UserRepository()
        } catch {
            fatalError("Failed to initialize repositories: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Places a bet
    /// - Parameters:
    ///   - team: The team being bet on
    ///   - isHomeTeam: Whether the bet is on the home team
    func placeBet(team: String, isHomeTeam: Bool) async throws -> Bool {
        guard !isProcessing else { return false }
        guard let amount = Int(betAmount), amount > 0 else {
            errorMessage = "Invalid bet amount"
            return false
        }
        
        // Additional validation for green coins
        if selectedCoinType == .green {
            // Check daily limit
            if amount > remainingDailyLimit {
                errorMessage = "This bet would exceed your daily limit"
                return false
            }
        }
        
        isProcessing = true
        // Place the defer block here, before the do-catch
        defer { isProcessing = false }
        errorMessage = nil
        
        do {
            // Create bet
            let bet = Bet(
                userId: user.id,
                gameId: game.id,
                coinType: selectedCoinType,
                amount: amount,
                initialSpread: isHomeTeam ? game.spread : -game.spread,
                team: team,
                isHomeTeam: isHomeTeam
            )
            
            // Place bet using repository
            try await betRepository.save(bet)
            
            // Update user's daily limit for green coins
            if selectedCoinType == .green {
                try await userRepository.updateDailyGreenCoinsUsage(
                    userId: user.id,
                    amount: amount
                )
            }
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Validates bet amount
    private func validateBetAmount(_ amount: Int) -> Bool {
        // Minimum bet amount
        guard amount >= 1 else { return false }
        
        // Maximum bet amount (could be moved to settings)
        guard amount <= 100 else { return false }
        
        // For green coins, check daily limit
        if selectedCoinType == .green {
            return amount <= remainingDailyLimit
        }
        
        return true
    }
}
