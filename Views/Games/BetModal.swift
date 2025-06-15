//
//  BetModal.swift
//  BettorOdds
//
//  Version: 2.4.1 - Fixed complex expression compilation issue
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
    
    // MARK: - Computed Properties
    
    private var canShowWinnings: Bool {
        !betAmount.isEmpty && Int(betAmount) != nil && Int(betAmount)! > 0 && !selectedTeam.isEmpty
    }
    
    private var canPlaceBet: Bool {
        guard let amount = Int(betAmount), amount > 0 else { return false }
        guard !selectedTeam.isEmpty else { return false }
        guard !game.isLocked else { return false }
        
        if selectedCoinType == .green {
            let remainingDailyLimit = user.remainingDailyGreenCoins
            return amount <= remainingDailyLimit && amount <= user.greenCoins
        }
        
        return amount <= user.yellowCoins
    }
    
    private var potentialWinnings: String {
        guard let amount = Double(betAmount) else { return "0" }
        return String(format: "%.0f", amount)
    }
    
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
                    .foregroundColor(Color.primary)
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
        .background(gameInfoBackground)
    }
    
    // MARK: - Helper Views for Complex Expressions
    
    private var gameInfoBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
            )
    }
    
    // MARK: - Team Selection Section (FIXED - Split Complex Expression)
    
    private var teamSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Team")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            teamSelectionCard
        }
        .padding(20)
        .background(teamSelectionBackground)
    }
    
    // Broken down complex team selection into smaller components
    private var teamSelectionCard: some View {
        HStack(spacing: 0) {
            awayTeamButton
            vsIndicator
            homeTeamButton
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(teamSelectionBorder)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var teamSelectionBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
    
    private var teamSelectionBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
    }
    
    // Away Team Button
    private var awayTeamButton: some View {
        Button(action: {
            selectedTeam = game.awayTeam
            isHomeTeam = false
            HapticManager.impact(.medium)
        }) {
            awayTeamContent
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(awayTeamBackground)
                .overlay(awayTeamSelectionBorder)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(selectedTeam == game.awayTeam ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTeam == game.awayTeam)
    }
    
    private var awayTeamContent: some View {
        VStack(spacing: 12) {
            Text(game.awayTeam)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            
            awaySpreadLabel
        }
    }
    
    private var awaySpreadLabel: some View {
        Text(game.awaySpread)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(awaySpreadBackground)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    private var awaySpreadBackground: some View {
        Capsule()
            .fill(Color.white.opacity(0.2))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
    }
    
    private var awayTeamBackground: some View {
        LinearGradient(
            colors: [
                game.awayTeamColors.primary.opacity(selectedTeam == game.awayTeam ? 0.9 : 0.7),
                game.awayTeamColors.secondary.opacity(selectedTeam == game.awayTeam ? 0.7 : 0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var awayTeamSelectionBorder: some View {
        Rectangle()
            .stroke(
                selectedTeam == game.awayTeam ? Color.white.opacity(0.8) : Color.clear,
                lineWidth: 3
            )
    }
    
    // VS Indicator
    private var vsIndicator: some View {
        VStack {
            Text("@")
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(vsIndicatorBackground)
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
        }
        .frame(width: 50)
        .zIndex(1)
    }
    
    private var vsIndicatorBackground: some View {
        Circle()
            .fill(Color.black.opacity(0.6))
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    // Home Team Button
    private var homeTeamButton: some View {
        Button(action: {
            selectedTeam = game.homeTeam
            isHomeTeam = true
            HapticManager.impact(.medium)
        }) {
            homeTeamContent
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(homeTeamBackground)
                .overlay(homeTeamSelectionBorder)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(selectedTeam == game.homeTeam ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTeam == game.homeTeam)
    }
    
    private var homeTeamContent: some View {
        VStack(spacing: 12) {
            Text(game.homeTeam)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            
            homeSpreadLabel
        }
    }
    
    private var homeSpreadLabel: some View {
        Text(game.homeSpread)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(homeSpreadBackground)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    private var homeSpreadBackground: some View {
        Capsule()
            .fill(Color.white.opacity(0.2))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
    }
    
    private var homeTeamBackground: some View {
        LinearGradient(
            colors: [
                game.homeTeamColors.primary.opacity(selectedTeam == game.homeTeam ? 0.9 : 0.7),
                game.homeTeamColors.secondary.opacity(selectedTeam == game.homeTeam ? 0.7 : 0.5)
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
    
    private var homeTeamSelectionBorder: some View {
        Rectangle()
            .stroke(
                selectedTeam == game.homeTeam ? Color.white.opacity(0.8) : Color.clear,
                lineWidth: 3
            )
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
        .background(coinTypeSectionBackground)
    }
    
    private var coinTypeSectionBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
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
            .background(coinTypeButtonBackground(isSelected: isSelected))
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
    
    private func coinTypeButtonBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(isSelected ? 0.15 : 0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.primary : Color.white.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
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
                    .background(betAmountFieldBackground)
                
                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(20)
        .background(betAmountSectionBackground)
    }
    
    private var betAmountFieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var betAmountSectionBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
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
                    .font(.system(size: 24))
                
                Text(potentialWinnings)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(potentialWinningsBackground)
    }
    
    private var potentialWinningsBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.primary.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
            )
    }
    
    // MARK: - Place Bet Button
    
    private var placeBetButton: some View {
        Button(action: {
            Task {
                await placeBet()
            }
        }) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Text("Place Bet")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(placeBetButtonBackground)
        }
        .disabled(!canPlaceBet || isProcessing)
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(canPlaceBet && !isProcessing ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: canPlaceBet)
        .padding(.top, 8)
    }
    
    private var placeBetButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: canPlaceBet && !isProcessing ?
                        [Color.primary, Color.primary.opacity(0.8)] :
                        [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(
                color: canPlaceBet && !isProcessing ? Color.primary.opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
    }
    
    // MARK: - Helper Functions
    
    private func placeBet() async {
        guard canPlaceBet else { return }
        
        isProcessing = true
        validationMessage = ""
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Show success and dismiss
        showSuccess = true
        isProcessing = false
    }
}

#Preview {
    BetModal(
        game: Game.sampleGames[0],
        user: User.preview,
        isPresented: .constant(true)
    )
}
