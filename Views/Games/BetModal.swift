//
//  BetModal.swift
//  BettorOdds
//
//  Version: 4.3.0 - Complete clean implementation
//  Replace entire file with this version
//  Updated: June 2025
//

import SwiftUI

struct BetModal: View {
    let game: Game
    let user: User
    @Binding var isPresented: Bool
    let preselectedTeam: String?
    
    @StateObject private var viewModel: BetModalViewModel
    @State private var selectedTeam: String?
    @State private var showSuccess = false
    @State private var isProcessing = false
    
    // Teal color definition for consistency
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    init(game: Game, user: User, isPresented: Binding<Bool>, preselectedTeam: String? = nil) {
        self.game = game
        self.user = user
        self._isPresented = isPresented
        self.preselectedTeam = preselectedTeam
        self._viewModel = StateObject(wrappedValue: BetModalViewModel(game: game, user: user))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
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
                        // IMPROVED: Top info section with better hierarchy
                        improvedTopSection
                        
                        // Team selection
                        teamSelectionSection
                        
                        // Coin type selection
                        coinTypeSection
                        
                        // Bet amount
                        betAmountSection
                        
                        // Potential winnings
                        potentialWinningsSection
                        
                        // Place bet button
                        placeBetButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .principal) {
                Text("Place Your Bet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            if let preselected = preselectedTeam {
                selectedTeam = preselected
            }
        }
        .alert("Bet Placed!", isPresented: $showSuccess) {
            Button("OK") {
                isPresented = false
            }
        } message: {
            Text("Your bet has been successfully placed and will be matched with another player.")
        }
    }
    
    // MARK: - IMPROVED Top Section (Better Hierarchy)
    
    private var improvedTopSection: some View {
        VStack(spacing: 16) {
            // Main matchup display
            HStack(spacing: 12) {
                // Away team
                VStack(spacing: 4) {
                    Text(game.awayTeam)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(game.awaySpread)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                
                // VS indicator with improved styling
                VStack(spacing: 2) {
                    Text("@")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(tealColor.opacity(0.3))
                                .overlay(
                                    Circle()
                                        .stroke(tealColor, lineWidth: 1)
                                )
                        )
                }
                
                // Home team
                VStack(spacing: 4) {
                    Text(game.homeTeam)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(game.homeSpread)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
            }
            
            // IMPROVED: Smaller, less assuming date/time section
            HStack {
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(game.time.formatted(.dateTime.month().day().hour().minute()))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
                
                Spacer()
            }
            
            // League badge
            HStack {
                Spacer()
                
                Text(game.league)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(tealColor.opacity(0.3))
                            .overlay(
                                Capsule()
                                    .stroke(tealColor, lineWidth: 1)
                            )
                    )
                
                Spacer()
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(tealColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Enhanced Team Selection Section
    
    private var teamSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Team")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                // Away team button
                teamSelectionButton(
                    teamName: game.awayTeam,
                    spread: game.awaySpread,
                    isSelected: selectedTeam == game.awayTeam,
                    action: {
                        selectedTeam = game.awayTeam
                        HapticManager.impact(.medium)
                    }
                )
                
                // Home team button
                teamSelectionButton(
                    teamName: game.homeTeam,
                    spread: game.homeSpread,
                    isSelected: selectedTeam == game.homeTeam,
                    action: {
                        selectedTeam = game.homeTeam
                        HapticManager.impact(.medium)
                    }
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private func teamSelectionButton(teamName: String, spread: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(teamName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(spread)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                            tealColor.opacity(0.3) :
                            Color.white.opacity(0.05)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? tealColor : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    // MARK: - Enhanced Coin Type Section
    
    private var coinTypeSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Yellow Coins
                Button(action: {
                    viewModel.selectedCoinType = .yellow
                }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 20, height: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Play Coins")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("\(user.yellowCoins)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(coinTypeButtonBackground(isSelected: viewModel.selectedCoinType == .yellow))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Green Coins with teal heart
                Button(action: {
                    viewModel.selectedCoinType = .green
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                            .foregroundColor(tealColor) // Using teal as requested
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Real Coins")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("\(user.greenCoins)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(coinTypeButtonBackground(isSelected: viewModel.selectedCoinType == .green))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Daily limit info for green coins
            if viewModel.selectedCoinType == .green {
                HStack {
                    Text("Daily Limit Remaining:")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(tealColor)
                        
                        Text("\(viewModel.remainingDailyLimit)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(tealColor)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func coinTypeButtonBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(isSelected ? 0.15 : 0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? tealColor : Color.white.opacity(0.2),
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
                
                // FIXED: Optional string handling
                if let validationMessage = viewModel.validationMessage, !validationMessage.isEmpty {
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
                    .stroke(tealColor.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var betAmountSectionBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(tealColor.opacity(0.3), lineWidth: 1)
            )
    }
    
    // MARK: - Enhanced Potential Winnings (More Prominent)
    
    private var potentialWinningsSection: some View {
        VStack(spacing: 16) {
            Text("Potential Winnings")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                // Coin icon
                Text(viewModel.selectedCoinType == .yellow ? "🟡" : "💚")
                    .font(.system(size: 32))
                
                // Amount with enhanced styling
                Text(viewModel.potentialWinnings)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: tealColor.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Spacer()
                
                // Win indicator
                VStack {
                    Text("YOU WIN")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(tealColor)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 16))
                        .foregroundColor(tealColor)
                }
            }
        }
        .padding(24)
        .background(potentialWinningsBackground)
    }
    
    private var potentialWinningsBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        tealColor.opacity(0.15),
                        tealColor.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(tealColor.opacity(0.4), lineWidth: 2)
            )
            .shadow(color: tealColor.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Enhanced Place Bet Button
    
    private var placeBetButton: some View {
        Button(action: {
            Task {
                await placeBet()
            }
        }) {
            HStack(spacing: 12) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    
                    Text("Place Bet")
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(placeBetButtonBackground)
        }
        .disabled(!viewModel.canPlaceBet || isProcessing)
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(viewModel.canPlaceBet && !isProcessing ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.canPlaceBet)
        .padding(.top, 8)
    }
    
    private var placeBetButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: viewModel.canPlaceBet && !isProcessing ?
                        [tealColor, tealColor.opacity(0.8)] :
                        [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(
                color: viewModel.canPlaceBet && !isProcessing ? tealColor.opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
    }
    
    // MARK: - Helper Functions
    
    private func placeBet() async {
        guard viewModel.canPlaceBet else { return }
        guard let selectedTeam = selectedTeam else { return }
        
        isProcessing = true
        
        // Use existing viewModel method
        let isHomeTeam = selectedTeam == game.homeTeam
        
        do {
            let success = try await viewModel.placeBet(team: selectedTeam, isHomeTeam: isHomeTeam)
            
            if success {
                showSuccess = true
                // FIXED: Use proper haptic feedback method
                HapticManager.impact(.light)
            }
        } catch {
            // Handle error appropriately
            print("Error placing bet: \(error)")
        }
        
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
