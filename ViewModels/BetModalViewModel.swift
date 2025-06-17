//
//  BetModalViewModel.swift
//  BettorOdds
//
//  Version: 3.0.0 - Updated with Dependency Injection and optimized for performance
//  Updated: June 2025
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
    
    // Dependencies using Dependency Injection
    @Inject private var betRepository: BetRepository
    @Inject private var userRepository: UserRepository
    
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
        
        super.init()
        
        print("💰 BetModalViewModel initialized with DI for game: \(game.homeTeam) vs \(game.awayTeam)")
    }
    
    // MARK: - Public Methods
    
    /// Places a bet
    /// - Parameters:
    ///   - team: The team being bet on
    ///   - isHomeTeam: Whether the bet is on the home team
    func placeBet(team: String, isHomeTeam: Bool) async throws -> Bool {
        guard !isProcessing else {
            print("⚠️ Bet placement already in progress")
            return false
        }
        
        guard let amount = Int(betAmount), amount > 0 else {
            validationMessage = "Invalid bet amount"
            print("❌ Invalid bet amount: \(betAmount)")
            return false
        }
        
        // Additional validation for green coins
        if selectedCoinType == .green {
            // Check daily limit
            if amount > remainingDailyLimit {
                validationMessage = "This bet would exceed your daily limit"
                print("❌ Daily limit exceeded: \(amount) > \(remainingDailyLimit)")
                return false
            }
        }
        
        isProcessing = true
        validationMessage = nil
        
        defer {
            isProcessing = false
        }
        
        do {
            print("🎯 Placing bet: \(amount) \(selectedCoinType.rawValue) coins on \(team)")
            
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
            
            // Save the bet
            try await betRepository.save(bet)
            print("✅ Bet saved successfully: \(bet.id)")
            
            // Update user balance
            try await updateUserBalance(amount: -amount)
            print("✅ User balance updated")
            
            // Show success
            showSuccess = true
            
            // Reset form
            resetForm()
            
            return true
            
        } catch {
            print("❌ Error placing bet: \(error.localizedDescription)")
            validationMessage = "Failed to place bet: \(error.localizedDescription)"
            handleError(AppError.unknown(error.localizedDescription))
            return false
        }
    }
    
    /// Validates the current bet inputs
    func validateBet() -> String? {
        guard let amount = Int(betAmount), amount > 0 else {
            return "Please enter a valid bet amount"
        }
        
        if game.isLocked {
            return "This game is locked for betting"
        }
        
        if selectedCoinType == .green {
            if amount > user.greenCoins {
                return "Insufficient green coins"
            }
            
            if amount > remainingDailyLimit {
                return "Would exceed daily limit"
            }
        } else {
            if amount > user.yellowCoins {
                return "Insufficient yellow coins"
            }
        }
        
        return nil
    }
    
    /// Updates validation message when inputs change
    func updateValidation() {
        validationMessage = validateBet()
    }
    
    /// Switches between coin types
    func switchCoinType(to coinType: CoinType) {
        selectedCoinType = coinType
        updateValidation()
        print("💰 Switched to \(coinType.rawValue) coins")
    }
    
    /// Sets a predefined bet amount
    func setBetAmount(_ amount: Int) {
        betAmount = String(amount)
        updateValidation()
        print("💵 Set bet amount to \(amount)")
    }
    
    // MARK: - Private Methods
    
    /// Updates user balance after bet placement
    private func updateUserBalance(amount: Int) async throws {
        try await userRepository.updateBalance(
            userId: user.id,
            coinType: selectedCoinType,
            amount: amount
        )
        
        // Update daily usage for green coins
        if selectedCoinType == .green {
            try await userRepository.updateDailyGreenCoinsUsage(
                userId: user.id,
                amount: abs(amount)
            )
        }
    }
    
    /// Resets the form after successful bet
    private func resetForm() {
        betAmount = ""
        validationMessage = nil
        print("🧹 Form reset after successful bet")
    }
    
    // MARK: - Helper Methods
    
    /// Gets the formatted balance for current coin type
    func getFormattedBalance() -> String {
        let balance = selectedCoinType == .yellow ? user.yellowCoins : user.greenCoins
        return "\(balance) \(selectedCoinType.emoji)"
    }
    
    /// Gets the formatted daily limit remaining
    func getFormattedDailyLimit() -> String {
        return "\(remainingDailyLimit) remaining today"
    }
    
    /// Checks if we should show daily limit warning
    func shouldShowDailyLimitWarning() -> Bool {
        guard selectedCoinType == .green,
              let amount = Int(betAmount),
              amount > 0 else { return false }
        
        let percentUsed = Double(amount) / Double(remainingDailyLimit)
        return percentUsed > 0.8 // Show warning if using more than 80% of remaining limit
    }
    
    /// Gets warning message for high daily limit usage
    func getDailyLimitWarning() -> String? {
        guard shouldShowDailyLimitWarning(),
              let amount = Int(betAmount) else { return nil }
        
        let remaining = remainingDailyLimit - amount
        if remaining <= 0 {
            return "This bet will reach your daily limit"
        } else {
            return "Only \(remaining) green coins will remain after this bet"
        }
    }
}

// MARK: - Extensions

extension BetModalViewModel {
    /// Quick bet amounts for user convenience
    var quickBetAmounts: [Int] {
        let maxAmount = selectedCoinType == .yellow ? user.yellowCoins : min(user.greenCoins, remainingDailyLimit)
        
        let amounts = [10, 25, 50, 100]
        return amounts.filter { $0 <= maxAmount }
    }
    
    /// Formatted spread display
    var formattedSpread: String {
        let spread = game.spread
        if spread > 0 {
            return "+\(spread)"
        } else {
            return "\(spread)"
        }
    }
    
    /// Game time display
    var gameTimeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: game.time)
    }
}
