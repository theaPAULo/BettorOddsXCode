//
//  BetModal.swift
//  BettorOdds
//
//  Version: 2.4.0 - Fixed button contrast and teal accents
//  Updated: June 2025

import Foundation
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
                AppTheme.Colors.background
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
                    .foregroundColor(AppTheme.Colors.primary) // FIXED: Teal cancel button
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
                        .fill(AppTheme.Colors.primary.opacity(0.8)) // FIXED: Teal background
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1) // FIXED: Teal border
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
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1) // FIXED: Teal border
                )
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
                                isSelected ? AppTheme.Colors.primary.opacity(0.8) : Color.white.opacity(0.2), // FIXED: Teal border when selected
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
    
    // MARK: - Coin Type Selection
    
    private var coinTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pick Your Coin Type")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                coinTypeButton(
                    type: .yellow,
                    emoji: "🟡",
                    title: "Play Coins",
                    isSelected: selectedCoinType == .yellow
                )
                
                coinTypeButton(
                    type: .green,
                    emoji: "💚",
                    title: "Real Coins",
                    isSelected: selectedCoinType == .green
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1) // FIXED: Teal border
                )
        )
    }
    
    private func coinTypeButton(type: CoinType, emoji: String, title: String, isSelected: Bool) -> some View {
        Button(action: {
            selectedCoinType = type
        }) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 32))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? AppTheme.Colors.primary : Color.white.opacity(0.2), // FIXED: Teal border when selected
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
    
    // MARK: - Bet Amount Section
    
    private var betAmountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enter Bet Amount")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                TextField("Enter amount", text: $betAmount)
                    .keyboardType(.numberPad)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1) // FIXED: Teal border
                            )
                    )
                
                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1) // FIXED: Teal border
                )
        )
    }
    
    // MARK: - Potential Winnings
    
    private var potentialWinningsSection: some View {
        VStack(spacing: 12) {
            Text("Potential Winnings")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack {
                Text(selectedCoinType == .yellow ? "🟡" : "💚")
                    .font(.title2)
                
                Text("\(potentialWinnings)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.Colors.primary) // FIXED: Teal color for winnings
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.primary.opacity(0.1)) // FIXED: Teal background tint
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.primary.opacity(0.5), lineWidth: 1) // FIXED: Teal border
                )
        )
    }
    
    // MARK: - Place Bet Button
    
    private var placeBetButton: some View {
        Button(action: {
            // Place bet logic here
            isProcessing = true
            // Simulate processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isProcessing = false
                showSuccess = true
            }
        }) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Place Bet")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white) // FIXED: Explicit white text for contrast
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: canPlaceBet ? [
                                AppTheme.Colors.primary,
                                AppTheme.Colors.primary.opacity(0.8)
                            ] : [
                                Color.gray.opacity(0.5),
                                Color.gray.opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(
                color: canPlaceBet ? AppTheme.Colors.primary.opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(!canPlaceBet || isProcessing)
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(canPlaceBet ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: canPlaceBet)
    }
    
    // MARK: - Computed Properties
    
    private var canShowWinnings: Bool {
        !selectedTeam.isEmpty && !betAmount.isEmpty && Double(betAmount) != nil
    }
    
    private var potentialWinnings: Int {
        guard let amount = Double(betAmount) else { return 0 }
        return Int(amount * 1.9) // Simplified calculation
    }
    
    private var canPlaceBet: Bool {
        !selectedTeam.isEmpty &&
        !betAmount.isEmpty &&
        Double(betAmount) != nil &&
        Double(betAmount)! > 0 &&
        validationMessage.isEmpty
    }
}
