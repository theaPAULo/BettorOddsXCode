//
//  BetModal.swift
//  BettorOdds
//
//  Version: 2.3.0 - Final working version with all fixes
//  Updated: June 2025

import SwiftUI

struct BetModal: View {
    let game: Game
    let user: User
    @Binding var isPresented: Bool
    
    @State private var selectedTeam: String = ""
    @State private var isHomeTeam: Bool = false
    @State private var selectedCoinType: CoinType = .yellow
    @State private var betAmount: String = ""
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var validationMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.13, blue: 0.15),
                        Color(red: 0.13, green: 0.23, blue: 0.26),
                        Color(red: 0.17, green: 0.33, blue: 0.39)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        gameInfoSection
                        teamSelectionSection
                        coinTypeSection
                        betAmountSection
                        if canShowWinnings {
                            potentialWinningsSection
                        }
                        placeBetButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Place Your Bet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK") {
                isPresented = false
            }
        } message: {
            Text("Your bet has been placed successfully!")
        }
    }
    
    // MARK: - Game Info Section
    
    private var gameInfoSection: some View {
        VStack(spacing: 12) {
            Text("\(game.awayTeam) @ \(game.homeTeam)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(game.time.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text(game.league)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.primary.opacity(0.8))
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Team Selection
    
    private var teamSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Team")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                // Away Team
                teamButton(
                    name: game.awayTeam,
                    spread: game.awaySpread,
                    colors: game.awayTeamColors,
                    isSelected: selectedTeam == game.awayTeam
                ) {
                    selectedTeam = game.awayTeam
                    isHomeTeam = false
                }
                
                // Home Team
                teamButton(
                    name: game.homeTeam,
                    spread: game.homeSpread,
                    colors: game.homeTeamColors,
                    isSelected: selectedTeam == game.homeTeam
                ) {
                    selectedTeam = game.homeTeam
                    isHomeTeam = true
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func teamButton(name: String, spread: String, colors: TeamColors, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 35)
                
                Text(spread)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                colors.primary.opacity(isSelected ? 1.0 : 0.7),
                                colors.secondary.opacity(isSelected ? 0.8 : 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.white.opacity(0.6) : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    // MARK: - Coin Type Selection
    
    private var coinTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pick Your Coin Type")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                // Yellow Coins
                coinButton(
                    type: .yellow,
                    balance: user.yellowCoins,
                    isSelected: selectedCoinType == .yellow
                ) {
                    selectedCoinType = .yellow
                }
                
                // Green Coins
                coinButton(
                    type: .green,
                    balance: user.greenCoins,
                    isSelected: selectedCoinType == .green
                ) {
                    selectedCoinType = .green
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func coinButton(type: CoinType, balance: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(type.emoji)
                    .font(.system(size: 36))
                
                Text(type.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Balance: \(balance)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? coinColor(type).opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? coinColor(type) : coinColor(type).opacity(0.3),
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func coinColor(_ type: CoinType) -> Color {
        switch type {
        case .yellow:
            return .yellow
        case .green:
            return .primary
        }
    }
    
    // MARK: - Bet Amount Section
    
    private var betAmountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enter Bet Amount")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            TextField("Amount", text: $betAmount)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.5), lineWidth: 2)
                        )
                )
                .keyboardType(.numberPad)
            
            if !validationMessage.isEmpty {
                Text(validationMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Potential Winnings
    
    private var canShowWinnings: Bool {
        guard let amount = Int(betAmount), amount > 0 else { return false }
        return true
    }
    
    private var potentialWinningsSection: some View {
        VStack(spacing: 12) {
            Text("Potential Winnings")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                Text(selectedCoinType.emoji)
                    .font(.system(size: 24))
                
                Text(calculateWinnings())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.primary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func calculateWinnings() -> String {
        guard let amount = Int(betAmount) else { return "0" }
        return "\(amount)" // Even odds: bet amount = winnings
    }
    
    // MARK: - Place Bet Button
    
    private var placeBetButton: some View {
        Button(action: placeBet) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isProcessing ? "Placing Bet..." : "Place Bet")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        canPlaceBet
                            ? Color.primary
                            : Color.gray.opacity(0.5)
                    )
            )
        }
        .disabled(!canPlaceBet)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var canPlaceBet: Bool {
        guard !selectedTeam.isEmpty else { return false }
        guard let amount = Int(betAmount), amount > 0 else { return false }
        guard !isProcessing else { return false }
        
        if selectedCoinType == .yellow {
            return amount <= user.yellowCoins
        } else {
            return amount <= user.greenCoins && amount <= 100 // Daily limit
        }
    }
    
    private func placeBet() {
        guard !selectedTeam.isEmpty else {
            validationMessage = "Please select a team"
            return
        }
        
        guard let amount = Int(betAmount), amount > 0 else {
            validationMessage = "Please enter a valid amount"
            return
        }
        
        // Simple validation
        if selectedCoinType == .yellow && amount > user.yellowCoins {
            validationMessage = "Insufficient yellow coins"
            return
        }
        
        if selectedCoinType == .green && amount > user.greenCoins {
            validationMessage = "Insufficient green coins"
            return
        }
        
        validationMessage = ""
        isProcessing = true
        
        // Simulate bet placement
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isProcessing = false
            showSuccess = true
        }
    }
}

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
