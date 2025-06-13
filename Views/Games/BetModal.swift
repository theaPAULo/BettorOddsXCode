//
//  BetModal.swift
//  BettorOdds
//
//  Version: 2.1.0 - Simplified working version without binding issues
//

import SwiftUI

struct BetModal: View {
    let game: Game
    let user: User
    @Binding var isPresented: Bool
    
    @StateObject private var viewModel: BetModalViewModel
    @State private var selectedTeam: String = ""
    @State private var isHomeTeam: Bool = false
    @FocusState private var isAmountFieldFocused: Bool
    
    init(game: Game, user: User, isPresented: Binding<Bool>) {
        self.game = game
        self.user = user
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: BetModalViewModel(game: game, user: user))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Game Info Header
                        gameInfoSection
                        
                        // Team Selection
                        teamSelectionSection
                        
                        // Coin Type Selection
                        coinTypeSection
                        
                        // Bet Amount
                        betAmountSection
                        
                        // Potential Winnings
                        potentialWinningsSection
                        
                        // Place Bet Button
                        placeBetButton
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Place Bet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .alert("Success!", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    isPresented = false
                }
            } message: {
                Text("Your bet has been placed successfully!")
            }
        }
        .onAppear {
            viewModel.clearValidation()
        }
        .onChange(of: viewModel.betAmount) { _, _ in
            viewModel.validateBet()
        }
        .errorHandling(viewModel: viewModel)
    }
    
    // MARK: - Game Info Section
    
    private var gameInfoSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("\(game.awayTeam) @ \(game.homeTeam)")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(game.time.formatted(date: .abbreviated, time: .shortened))
                .font(AppTheme.Typography.callout)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(game.league)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.CornerRadius.small)
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
    
    // MARK: - Team Selection
    
    private var teamSelectionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Select Team")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            HStack(spacing: AppTheme.Spacing.md) {
                // Away Team Button
                TeamSelectionButton(
                    teamName: game.awayTeam,
                    spread: game.awaySpread,
                    isSelected: selectedTeam == game.awayTeam,
                    teamColors: game.awayTeamColors
                ) {
                    selectedTeam = game.awayTeam
                    isHomeTeam = false
                    HapticManager.selection()
                }
                
                // Home Team Button
                TeamSelectionButton(
                    teamName: game.homeTeam,
                    spread: game.homeSpread,
                    isSelected: selectedTeam == game.homeTeam,
                    teamColors: game.homeTeamColors
                ) {
                    selectedTeam = game.homeTeam
                    isHomeTeam = true
                    HapticManager.selection()
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
    
    // MARK: - Coin Type Selection
    
    private var coinTypeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Select Coin Type")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            HStack(spacing: AppTheme.Spacing.md) {
                // Yellow Coins
                CoinSelectionButton(
                    type: .yellow,
                    isSelected: viewModel.selectedCoinType == .yellow,
                    balance: user.yellowCoins
                ) {
                    viewModel.selectedCoinType = .yellow
                    HapticManager.selection()
                }
                
                // Green Coins
                CoinSelectionButton(
                    type: .green,
                    isSelected: viewModel.selectedCoinType == .green,
                    balance: user.greenCoins
                ) {
                    viewModel.selectedCoinType = .green
                    HapticManager.selection()
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
    
    // MARK: - Bet Amount Section
    
    private var betAmountSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Bet Amount")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            HStack {
                Text(viewModel.coinTypeEmoji)
                    .font(.title2)
                
                TextField("0", text: $viewModel.betAmount)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isAmountFieldFocused)
            }
            
            // Validation message
            if let validationMessage = viewModel.validationMessage {
                Text(validationMessage)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.error)
            }
            
            // Daily limit for green coins
            if viewModel.selectedCoinType == .green {
                Text("Daily limit: \(user.dailyGreenCoinsUsed)/100")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
    
    // MARK: - Potential Winnings
    
    private var potentialWinningsSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("Potential Winnings")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            HStack {
                Text(viewModel.coinTypeEmoji)
                    .font(.title)
                Text(viewModel.potentialWinnings)
                    .font(AppTheme.Typography.amountLarge)
                    .foregroundColor(AppTheme.Colors.success)
                    .fontWeight(.bold)
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.success.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(AppTheme.Colors.success.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
    
    // MARK: - Place Bet Button
    
    private var placeBetButton: some View {
        Button(action: {
            placeBet()
        }) {
            HStack {
                if viewModel.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Place Bet")
                        .font(AppTheme.Typography.buttonLarge)
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(viewModel.canPlaceBet && !selectedTeam.isEmpty ? AppTheme.Colors.primary : AppTheme.Colors.buttonBackgroundDisabled)
            )
            .foregroundColor(.white)
        }
        .disabled(!viewModel.canPlaceBet || selectedTeam.isEmpty || viewModel.isProcessing)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.lg)
    }
    
    // MARK: - Actions
    
    private func placeBet() {
        guard !selectedTeam.isEmpty else {
            viewModel.validationMessage = "Please select a team"
            return
        }
        
        Task {
            do {
                let success = try await viewModel.placeBet(team: selectedTeam, isHomeTeam: isHomeTeam)
                if success {
                    HapticManager.notification(.success)
                } else {
                    HapticManager.notification(.error)
                }
            } catch {
                HapticManager.notification(.error)
            }
        }
    }
}

// MARK: - Supporting Views

struct TeamSelectionButton: View {
    let teamName: String
    let spread: String
    let isSelected: Bool
    let teamColors: TeamColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(teamName)
                    .font(AppTheme.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(spread)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                LinearGradient(
                    colors: [
                        teamColors.primary.opacity(isSelected ? 1.0 : 0.7),
                        teamColors.secondary.opacity(isSelected ? 0.8 : 0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(
                        isSelected ? Color.white.opacity(0.4) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CoinSelectionButton: View {
    let type: CoinType
    let isSelected: Bool
    let balance: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(type.emoji)
                    .font(.system(size: 32))
                
                Text(type.displayName)
                    .font(AppTheme.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Balance: \(balance)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(buttonBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(buttonBorder, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buttonBackground: Color {
        if isSelected {
            return type == .yellow ? AppTheme.Colors.yellowCoin.opacity(0.2) : AppTheme.Colors.greenCoin.opacity(0.2)
        }
        return AppTheme.Colors.cardBackground
    }
    
    private var buttonBorder: Color {
        if isSelected {
            return type == .yellow ? AppTheme.Colors.yellowCoin : AppTheme.Colors.greenCoin
        }
        return type == .yellow ? AppTheme.Colors.yellowCoin.opacity(0.3) : AppTheme.Colors.greenCoin.opacity(0.3)
    }
}

// MARK: - Preview
#Preview {
    BetModal(
        game: Game.sampleGames[0],
        user: User(
            id: "preview",
            displayName: "Preview User",
            authProvider: "google.com"
        ),
        isPresented: .constant(true)
    )
}
