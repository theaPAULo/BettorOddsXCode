//
//  BetModal.swift
//  BettorOdds
//
//  Created by Assistant on 1/30/25
//  Version: 2.1.0
//

import SwiftUI

struct BetModal: View {
    // MARK: - Properties
    let game: Game
    @Binding var isPresented: Bool
    @StateObject private var viewModel: BetModalViewModel
    @State private var selectedTeam: String?
    @State private var isHomeTeamSelected: Bool = false
    @State private var isShowingBiometricPrompt = false
    
    // MARK: - Initialization
    init(game: Game, user: User, isPresented: Binding<Bool>) {
        print("🎲 Initializing BetModal with game: \(game.id)")
        self._isPresented = isPresented
        self.game = game
        self._viewModel = StateObject(wrappedValue: BetModalViewModel(game: game, user: user))
    }
    
    // Background gradient for the modal
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                .primary.opacity(0.1),
                .backgroundPrimary.opacity(0.05),
                .primary.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time Display
                        Text(game.formattedTime)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .padding(.top, 8)
                        
                        // Team Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Team")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            GeometryReader { geometry in
                                HStack(spacing: 16) {
                                    // Away Team Button
                                    TeamSelectionButton(
                                        team: game.awayTeam,
                                        spread: -game.spread,
                                        teamColors: game.awayTeamColors,
                                        isSelected: selectedTeam == game.awayTeam,
                                        width: (geometry.size.width - 16) / 2
                                    ) {
                                        print("🏀 Selected away team: \(game.awayTeam)")
                                        selectedTeam = game.awayTeam
                                        isHomeTeamSelected = false
                                        hapticFeedback()
                                    }
                                    
                                    // Home Team Button
                                    TeamSelectionButton(
                                        team: game.homeTeam,
                                        spread: game.spread,
                                        teamColors: game.homeTeamColors,
                                        isSelected: selectedTeam == game.homeTeam,
                                        width: (geometry.size.width - 16) / 2
                                    ) {
                                        print("🏀 Selected home team: \(game.homeTeam)")
                                        selectedTeam = game.homeTeam
                                        isHomeTeamSelected = true
                                        hapticFeedback()
                                    }
                                }
                            }
                            .frame(height: 100)
                        }
                        
                        // Coin Type Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Coin Type")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            HStack(spacing: 16) {
                                CoinTypeButton(
                                    type: .yellow,
                                    isSelected: viewModel.selectedCoinType == .yellow
                                ) {
                                    print("💰 Selected yellow coins")
                                    viewModel.selectedCoinType = .yellow
                                    hapticFeedback()
                                }
                                
                                CoinTypeButton(
                                    type: .green,
                                    isSelected: viewModel.selectedCoinType == .green
                                ) {
                                    print("💰 Selected green coins")
                                    viewModel.selectedCoinType = .green
                                    hapticFeedback()
                                }
                            }
                        }
                        
                        // Bet Amount Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bet Amount")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            HStack {
                                Text(viewModel.selectedCoinType.emoji)
                                TextField("0", text: $viewModel.betAmount)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .foregroundColor(.textPrimary)
                            }
                            
                            if viewModel.selectedCoinType == .green {
                                Text("Daily Limit: \(viewModel.remainingDailyLimit) coins")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        // Potential Winnings
                        VStack(spacing: 8) {
                            Text("Potential Winnings")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            HStack {
                                Text(viewModel.selectedCoinType.emoji)
                                Text(viewModel.potentialWinnings)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.textPrimary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(12)
                        
                        // Error Message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.statusError)
                                .font(.system(size: 14))
                        }
                        
                        // Place Bet Button
                        Button(action: handlePlaceBet) {
                            if viewModel.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("PLACE BET")
                                    .font(.system(size: 18, weight: .heavy))
                                    .tracking(0.5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Group {
                                if viewModel.canPlaceBet && selectedTeam != nil {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .primary,
                                            .primary.opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    Color.textSecondary.opacity(0.3)
                                }
                            }
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.backgroundSecondary.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(
                            color: viewModel.canPlaceBet && selectedTeam != nil ?
                                .primary.opacity(0.3) : .clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                        .foregroundColor(.white)
                        .disabled(!viewModel.canPlaceBet || selectedTeam == nil || viewModel.isProcessing)
                    }
                    .padding()
                }
            }
            .navigationTitle("Place Bet")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") { isPresented = false })
            .sheet(isPresented: $isShowingBiometricPrompt) {
                BiometricPrompt(
                    title: "Confirm Bet",
                    subtitle: "Please authenticate to place bet with green coins"
                ) { success in
                    if success {
                        guard let team = selectedTeam else { return }
                        processBet(team: team)
                    }
                }
            }
            .onAppear {
                print("🎲 BetModal appeared")
                print("Game details: \(game.debugDescription())")
            }
        }
    }
    
    // MARK: - Methods
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func handlePlaceBet() {
        guard let team = selectedTeam else { return }
        print("🎲 Handling bet placement for team: \(team)")
        
        if viewModel.selectedCoinType == .green {
            print("💚 Green coins selected - showing biometric prompt")
                        isShowingBiometricPrompt = true
                    } else {
                        print("🟡 Yellow coins selected - processing bet directly")
                        processBet(team: team)
                    }
                }
                
                private func processBet(team: String) {
                    print("🎲 Processing bet for team: \(team)")
                    Task {
                        do {
                            let success = try await viewModel.placeBet(team: team, isHomeTeam: isHomeTeamSelected)
                            
                            await MainActor.run {
                                if success {
                                    print("✅ Bet placed successfully")
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                    isPresented = false
                                } else {
                                    print("❌ Failed to place bet")
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.error)
                                }
                            }
                        } catch {
                            print("❌ Error placing bet: \(error)")
                            await MainActor.run {
                                viewModel.errorMessage = error.localizedDescription
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.error)
                            }
                        }
                    }
                }
            }

            // MARK: - Supporting Components

            struct TeamSelectionButton: View {
                let team: String
                let spread: Double
                let teamColors: TeamColors
                let isSelected: Bool
                let width: CGFloat
                let action: () -> Void
                
                var body: some View {
                    Button(action: action) {
                        VStack(spacing: 12) {
                            Text(team)
                                .font(.system(size: 16, weight: .semibold))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(height: 40)
                                .foregroundColor(isSelected ? .white : .textPrimary)
                            
                            Text(spread >= 0 ? "+\(String(format: "%.1f", spread))" : "\(String(format: "%.1f", spread))")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(isSelected ? .white : .textPrimary)
                        }
                        .frame(width: width)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    teamColors.primary.opacity(isSelected ? 0.8 : 0.1),
                                    teamColors.secondary.opacity(isSelected ? 0.8 : 0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? teamColors.primary : teamColors.primary.opacity(0.3),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                    }
                }
            }

            struct CoinTypeButton: View {
                let type: CoinType
                let isSelected: Bool
                let action: () -> Void
                
                var body: some View {
                    Button(action: action) {
                        HStack {
                            Text(type.emoji)
                            Text(type.displayName)
                                .font(.system(size: 16))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(buttonBorder, lineWidth: isSelected ? 2 : 1)
                        )
                        .foregroundColor(isSelected ? .white : type == .yellow ? .yellow : .green)
                    }
                }
                
                private var buttonBackground: Color {
                    if isSelected {
                        return type == .yellow ? .yellow : .green
                    }
                    return type == .yellow ? .yellow.opacity(0.1) : .green.opacity(0.1)
                }
                
                private var buttonBorder: Color {
                    if isSelected {
                        return type == .yellow ? .yellow : .green
                    }
                    return type == .yellow ? .yellow.opacity(0.3) : .green.opacity(0.3)
                }
            }

            // MARK: - Preview Provider
            #Preview {
                BetModal(
                    game: Game.sampleGames[0],
                    user: User(id: "preview", email: "test@example.com"),
                    isPresented: .constant(true)
                )
            }
