//
//  BetModal.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 2.1.0
//

import SwiftUI

struct BetModal: View {
    // MARK: - Properties
    let game: Game
    let user: User // Make user accessible
    @Binding var isPresented: Bool
    @StateObject private var viewModel: BetModalViewModel
    @State private var selectedTeam: String?
    @State private var isHomeTeamSelected: Bool = false
    @State private var showConfirmation = false
    @State private var showBiometricAuth = false
    
    // MARK: - Initialization
    init(game: Game, user: User, isPresented: Binding<Bool>) {
        self.game = game
        self.user = user
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: BetModalViewModel(game: game, user: user))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Balance Header
                    balanceHeader
                    
                    // Game Info Section
                    gameInfoSection
                    
                    // Team Selection
                    teamSelectionSection
                    
                    // Coin Type Selection
                    coinTypeSection
                    
                    // Bet Amount Section
                    betAmountSection
                    
                    // Validation Messages
                    validationMessages
                    
                    // Potential Winnings
                    potentialWinningsSection
                    
                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(AppTheme.Status.error)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Place Bet Button
                    CustomButton(
                        title: viewModel.isProcessing ? "Processing..." : "Place Bet",
                        action: { showConfirmation = true },
                        isLoading: viewModel.isProcessing,
                        disabled: !canPlaceBet
                    )
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Place Bet")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: closeButton)
            .confirmationDialog(
                "Confirm Bet",
                isPresented: $showConfirmation,
                titleVisibility: .visible
            ) {
                Button("Place \(viewModel.selectedCoinType.emoji) \(viewModel.betAmount) Bet", role: .none) {
                    if viewModel.selectedCoinType == .green {
                        showBiometricAuth = true
                    } else {
                        handlePlaceBet()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to place this bet?")
            }
            .alert("Biometric Authentication Required",
                   isPresented: $showBiometricAuth) {
                Button("Authenticate") {
                    // TODO: Add biometric authentication
                    handlePlaceBet()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    // MARK: - Supporting Views
    
    private var closeButton: some View {
        Button("Close") {
            isPresented = false
        }
    }
    
    private var balanceHeader: some View {
        HStack {
            // Yellow Coins
            HStack(spacing: 4) {
                Text("🟡")
                Text("\(user.yellowCoins)")
                    .font(.system(size: 16, weight: .bold))
            }
            
            Spacer()
            
            // Green Coins
            HStack(spacing: 4) {
                Text("💚")
                Text("\(user.greenCoins)")
                    .font(.system(size: 16, weight: .bold))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(AppTheme.Background.card)
        .cornerRadius(12)
    }
    
    private var gameInfoSection: some View {
        VStack(spacing: 8) {
            Text("\(game.awayTeam) @ \(game.homeTeam)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.Text.primary)
            
            Text(game.formattedTime)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Text.secondary)
        }
        .padding()
        .background(AppTheme.Background.card)
        .cornerRadius(12)
    }
    
    private var teamSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Team")
                .font(.headline)
                .foregroundColor(AppTheme.Text.primary)
            
            HStack(spacing: 16) {
                // Away Team Button
                teamButton(team: game.awayTeam,
                          spread: -game.spread,
                          isSelected: selectedTeam == game.awayTeam,
                          isHome: false)
                
                // Home Team Button
                teamButton(team: game.homeTeam,
                          spread: game.spread,
                          isSelected: selectedTeam == game.homeTeam,
                          isHome: true)
            }
        }
    }
    
    private var coinTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Coin Type")
                .font(.headline)
                .foregroundColor(AppTheme.Text.primary)
            
            HStack(spacing: 16) {
                // Yellow Coins
                coinTypeButton(type: .yellow)
                
                // Green Coins
                coinTypeButton(type: .green)
            }
        }
    }
    
    private var betAmountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bet Amount")
                .font(.headline)
                .foregroundColor(AppTheme.Text.primary)
            
            HStack {
                Text(viewModel.selectedCoinType.emoji)
                TextField("0", text: $viewModel.betAmount)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            if viewModel.selectedCoinType == .green {
                Text("Daily Limit: \(viewModel.remainingDailyLimit) coins")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Text.secondary)
            }
        }
    }
    
    private var potentialWinningsSection: some View {
        VStack(spacing: 8) {
            Text("Potential Winnings")
                .font(.headline)
                .foregroundColor(AppTheme.Text.primary)
            
            HStack {
                Text(viewModel.selectedCoinType.emoji)
                Text("\(viewModel.potentialWinnings)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.Text.primary)
            }
        }
        .padding()
        .background(AppTheme.Background.card)
        .cornerRadius(12)
    }
    
    private var validationMessages: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let amount = Int(viewModel.betAmount) {
                if amount <= 0 {
                    ValidationMessage("Bet amount must be greater than 0", type: .error)
                }
                
                if viewModel.selectedCoinType == .green {
                    if amount > viewModel.remainingDailyLimit {
                        ValidationMessage("Exceeds daily limit of 100 green coins", type: .error)
                    } else if Double(amount) > Double(viewModel.remainingDailyLimit) * 0.8 {
                        ValidationMessage("Approaching daily limit", type: .warning)
                    }
                    
                    if amount > user.greenCoins {
                        ValidationMessage("Insufficient green coins", type: .error)
                    }
                } else {
                    if amount > user.yellowCoins {
                        ValidationMessage("Insufficient yellow coins", type: .error)
                    }
                }
            }
            
            if selectedTeam == nil {
                ValidationMessage("Select a team to bet on", type: .info)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var canPlaceBet: Bool {
        guard let selectedTeam = selectedTeam,
              !viewModel.betAmount.isEmpty,
              let amount = Int(viewModel.betAmount),
              amount > 0
        else { return false }
        
        if viewModel.selectedCoinType == .green {
            return amount <= viewModel.remainingDailyLimit && amount <= user.greenCoins
        }
        
        return amount <= user.yellowCoins
    }
    
    // MARK: - Helper Functions
    
    private func teamButton(team: String, spread: Double, isSelected: Bool, isHome: Bool) -> some View {
        Button(action: {
            selectedTeam = team
            isHomeTeamSelected = isHome
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            VStack(spacing: 8) {
                Text(team)
                    .font(.system(size: 16, weight: .medium))
                Text(spread > 0 ? "+\(String(format: "%.1f", spread))" : "\(String(format: "%.1f", spread))")
                    .font(.system(size: 14))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? AppTheme.Brand.primary.opacity(0.05) : AppTheme.Background.card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.Brand.primary.opacity(0.1) : Color.clear, lineWidth: 1)
            )
            .foregroundColor(isSelected ? AppTheme.Brand.primary : AppTheme.Text.primary)
        }
    }
    
    private func coinTypeButton(type: CoinType) -> some View {
        Button(action: {
            viewModel.selectedCoinType = type
        }) {
            HStack {
                Text(type.emoji)
                Text(type.displayName)
                    .font(.system(size: 16))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.selectedCoinType == type ?
                       (type == .yellow ? AppTheme.Coins.yellow.opacity(0.1) : AppTheme.Coins.green.opacity(0.1)) :
                        AppTheme.Background.card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.selectedCoinType == type ?
                           (type == .yellow ? AppTheme.Coins.yellow : AppTheme.Coins.green) :
                            Color.clear,
                           lineWidth: 2)
            )
            .foregroundColor(AppTheme.Text.primary)
        }
    }
    
    private func handlePlaceBet() {
        guard let team = selectedTeam else { return }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        Task {
            if let success = try? await viewModel.placeBet(team: team, isHomeTeam: isHomeTeamSelected) {
                if success {
                    // Post notification to refresh My Bets screen
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToMyBets"), object: nil)
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Supporting Structs

struct ValidationMessage: View {
    let message: String
    let type: ValidationType
    
    enum ValidationType {
        case error, warning, info
        
        var color: Color {
            switch self {
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .error: return "exclamationmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    init(_ message: String, type: ValidationType) {
        self.message = message
        self.type = type
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(type.color)
        }
    }
}

#Preview {
    BetModal(
        game: Game.sampleGames[0],
        user: User(id: "test", email: "test@example.com"),
        isPresented: .constant(true)
    )
}
