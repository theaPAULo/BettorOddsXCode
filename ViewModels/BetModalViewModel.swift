//
//  BetModalViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 2.1.0
//

import Foundation
import LocalAuthentication
import Combine

@MainActor
class BetModalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedCoinType: CoinType = .yellow
    @Published var betAmount: String = ""
    @Published var errorMessage: String?
    @Published var isProcessing = false
    @Published var showBiometricPrompt = false
    @Published var showConfirmation = false
    
    // MARK: - Private Properties
    private let game: Game
    private let user: User
    private var cancellables = Set<AnyCancellable>()
    private let betsManager: BetsManager
    
    // MARK: - Computed Properties
    var potentialWinnings: Int {
        guard let amount = Int(betAmount) else { return 0 }
        return Int(Double(amount) * 0.909)
    }
    
    var canPlaceBet: Bool {
        guard let amount = Int(betAmount),
              !betAmount.isEmpty,
              amount >= 1,
              amount <= 100 else {
            return false
        }
        
        if selectedCoinType == .green {
            return (user.dailyGreenCoinsUsed + amount) <= 100
        }
        
        return true
    }
    
    var remainingDailyLimit: Int {
        return 100 - user.dailyGreenCoinsUsed
    }
    
    // MARK: - Initialization
    init(game: Game, user: User, betsManager: BetsManager = .shared) {
        self.game = game
        self.user = user
        self.betsManager = betsManager
    }
    
    // MARK: - Public Methods
    func placeBet(team: String, isHomeTeam: Bool) async throws -> Bool {
        guard let amount = Int(betAmount) else {
            errorMessage = "Invalid bet amount"
            return false
        }
        
        // Validate amount
        guard Bet.validateBetAmount(amount,
                                  coinType: selectedCoinType,
                                  userDailyGreenCoinsUsed: user.dailyGreenCoinsUsed) else {
            errorMessage = "Invalid bet amount or daily limit exceeded"
            return false
        }
        
        // For green coins, require biometric authentication
        if selectedCoinType == .green {
            return try await authenticateAndPlaceBet(amount: amount, team: team, isHomeTeam: isHomeTeam)
        } else {
            return try await processBet(amount: amount, team: team, isHomeTeam: isHomeTeam)
        }
    }
    
    // MARK: - Private Methods
    private func authenticateAndPlaceBet(amount: Int, team: String, isHomeTeam: Bool) async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = "Biometric authentication not available"
            return false
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: "Authenticate to place bet with green coins") { success, error in
                Task { @MainActor in
                    if success {
                        do {
                            let result = try await self.processBet(amount: amount, team: team, isHomeTeam: isHomeTeam)
                            continuation.resume(returning: result)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    } else {
                        self.errorMessage = "Authentication failed"
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    private func processBet(amount: Int, team: String, isHomeTeam: Bool) async throws -> Bool {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let bet = Bet(
                userId: user.id,
                gameId: game.id,
                coinType: selectedCoinType,
                amount: amount,
                initialSpread: game.spread,
                team: team,
                isHomeTeam: isHomeTeam
            )
            
            // Save bet using BetsManager
            try await betsManager.placeBet(bet)
            
            // Update UI state
            showConfirmation = true
            return true
            
        } catch {
            errorMessage = "Failed to place bet: \(error.localizedDescription)"
            return false
        }
    }
}
