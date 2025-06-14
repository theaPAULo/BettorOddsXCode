//
//  BetModalViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 2.0.0 - Updated to inherit from BaseViewModel with all needed properties
//

import SwiftUI
import Foundation

@MainActor
class BetModalViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var selectedCoinType: CoinType = .yellow
    @Published var betAmount: String = ""
    @Published var isProcessing = false
    @Published var showSuccess = false
    @Published var validationMessage: String?
    
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
    
    var coinTypeEmoji: String {
        return selectedCoinType.emoji
    }
    
    var errorMessage: String? {
        return currentError?.localizedDescription
    }
    
    // Override isLoading to use our isProcessing state
    override var isLoading: Bool {
        return isProcessing
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
        
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Places a bet
    /// - Parameters:
    ///   - team: The team being bet on
    ///   - isHomeTeam: Whether the bet is on the home team
    func placeBet(team: String, isHomeTeam: Bool) async throws -> Bool {
        guard !isProcessing else { return false }
        guard let amount = Int(betAmount), amount > 0 else {
            validationMessage = "Invalid bet amount"
            return false
        }
        
        // Additional validation for green coins
        if selectedCoinType == .green {
            // Check daily limit
            if amount > remainingDailyLimit {
                validationMessage = "This bet would exceed your daily limit"
                return false
            }
        }
        
        isProcessing = true
        validationMessage = nil
        
        defer {
            isProcessing = false
        }
        
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
            
            // Save bet
            try await betRepository.save(bet)
            
            // Update user balance
            var updatedUser = user
            if selectedCoinType == .green {
                updatedUser.greenCoins -= amount
                updatedUser.dailyGreenCoinsUsed += amount
            } else {
                updatedUser.yellowCoins -= amount
            }
            
            try await userRepository.save(updatedUser)
            
            // Show success
            showSuccess = true
            
            return true
            
        } catch {
            handleError(AppError.unknown(error.localizedDescription))
            return false
        }
    }
    
    /// Validates the current bet configuration
    func validateBet() {
        guard let amount = Int(betAmount), amount > 0 else {
            validationMessage = "Enter a valid bet amount"
            return
        }
        
        if selectedCoinType == .green {
            if amount > remainingDailyLimit {
                validationMessage = "Exceeds daily limit (\(remainingDailyLimit) remaining)"
                return
            }
            
            if amount > user.greenCoins {
                validationMessage = "Insufficient green coins"
                return
            }
        } else {
            if amount > user.yellowCoins {
                validationMessage = "Insufficient yellow coins"
                return
            }
        }
        
        validationMessage = nil
    }
    
    /// Clears all validation messages
    func clearValidation() {
        validationMessage = nil
    }
}
