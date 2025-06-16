//
//  BetModal.swift
//  BettorOdds
//
//  Version: 3.0.0 - Complete redesign with Firebase integration and consistent UI
//  Updated: June 2025

import Foundation
import SwiftUI

struct BetModal: View {
    let game: Game
    let user: User
    @Binding var isPresented: Bool
    
    // ViewModel for proper bet management
    @StateObject private var viewModel: BetModalViewModel
    
    // Local UI state
    @State private var selectedTeam: String = ""
    @State private var isHomeTeam: Bool = false
    @State private var showSuccess = false
    @State private var showError = false
    
    // MARK: - Computed Properties
    
    private var canShowWinnings: Bool {
        !viewModel.betAmount.isEmpty &&
        Int(viewModel.betAmount) != nil &&
        Int(viewModel.betAmount)! > 0 &&
        !selectedTeam.isEmpty
    }
    
    private var homeSpread: Double {
        game.spread
    }
    
    private var awaySpread: Double {
        -game.spread
    }
    
    // MARK: - Initialization
    init(game: Game, user: User, isPresented: Binding<Bool>) {
        self.game = game
        self.user = user
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: BetModalViewModel(game: game, user: user))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching Games view
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        gameInfoHeader
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
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.validationMessage ?? "An error occurred")
        }
        .onChange(of: viewModel.showSuccess) { success in
            showSuccess = success
        }
        .onChange(of: viewModel.validationMessage) { message in
            showError = message != nil
        }
    }
    
    // MARK: - Game Info Header (Compact Design)
    
    private var gameInfoHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(game.awayTeam) @ \(game.homeTeam)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(game.time.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(game.league)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.primary.opacity(0.8))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Team Selection Section (With Team Gradients)
    
    private var teamSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Team")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 0) {
                // Away Team Button
                Button(action: {
                    selectedTeam = game.awayTeam
                    isHomeTeam = false
                }) {
                    VStack(spacing: 8) {
                        Text(game.awayTeam)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("\(awaySpread > 0 ? "+" : "")\(String(format: "%.1f", awaySpread))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(
                        LinearGradient(
                            colors: [
                                TeamColors.getTeamColors(game.awayTeam).primary,
                                TeamColors.getTeamColors(game.awayTeam).secondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Rectangle()
                            .stroke(
                                selectedTeam == game.awayTeam ? Color.white : Color.clear,
                                lineWidth: 3
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // VS Divider
                VStack {
                    Text("@")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                        )
                }
                .frame(width: 40)
                .zIndex(1)
                
                // Home Team Button
                Button(action: {
                    selectedTeam = game.homeTeam
                    isHomeTeam = true
                }) {
                    VStack(spacing: 8) {
                        Text(game.homeTeam)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("\(homeSpread > 0 ? "+" : "")\(String(format: "%.1f", homeSpread))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(
                        LinearGradient(
                            colors: [
                                TeamColors.getTeamColors(game.homeTeam).primary,
                                TeamColors.getTeamColors(game.homeTeam).secondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Rectangle()
                            .stroke(
                                selectedTeam == game.homeTeam ? Color.white : Color.clear,
                                lineWidth: 3
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Coin Type Section
    
    private var coinTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pick Your Coin Type")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                // Yellow Coins
                Button(action: {
                    viewModel.selectedCoinType = .yellow
                }) {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 30, height: 30)
                        
                        Text("Play Coins")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Balance: \(user.yellowCoins)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(coinTypeButtonBackground(isSelected: viewModel.selectedCoinType == .yellow))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Green Coins
                Button(action: {
                    viewModel.selectedCoinType = .green
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                        
                        Text("Real Coins")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Balance: \(user.greenCoins)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(coinTypeButtonBackground(isSelected: viewModel.selectedCoinType == .green))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
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
                TextField("Enter amount", text: $viewModel.betAmount)
                    .keyboardType(.numberPad)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(16)
                    .background(betAmountFieldBackground)
                
                if let message = viewModel.validationMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                // Show daily limit for green coins
                if viewModel.selectedCoinType == .green {
                    HStack {
                        Text("Daily Limit Remaining:")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text("💚 \(viewModel.remainingDailyLimit)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
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
                Text(viewModel.coinTypeEmoji)
                    .font(.system(size: 24))
                
                Text(viewModel.potentialWinnings)
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
                if viewModel.isProcessing {
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
        .disabled(!viewModel.canPlaceBet || viewModel.isProcessing || selectedTeam.isEmpty)
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(viewModel.canPlaceBet && !viewModel.isProcessing && !selectedTeam.isEmpty ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.canPlaceBet)
        .padding(.top, 8)
    }
    
    private var placeBetButtonBackground: some View {
        let canPlace = viewModel.canPlaceBet && !viewModel.isProcessing && !selectedTeam.isEmpty
        
        return RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: canPlace ?
                        [Color.primary, Color.primary.opacity(0.8)] :
                        [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(
                color: canPlace ? Color.primary.opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
    }
    
    // MARK: - Helper Functions
    
    private func placeBet() async {
        guard !selectedTeam.isEmpty else {
            viewModel.validationMessage = "Please select a team"
            return
        }
        
        do {
            let success = try await viewModel.placeBet(team: selectedTeam, isHomeTeam: isHomeTeam)
            if success {
                showSuccess = true
                // Small delay before dismissing to show success message
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isPresented = false
                }
            }
        } catch {
            print("❌ Error placing bet: \(error)")
            viewModel.validationMessage = error.localizedDescription
        }
    }
}

#Preview {
    BetModal(
        game: Game.sampleGames[0],
        user: User.preview,
        isPresented: .constant(true)
    )
}
