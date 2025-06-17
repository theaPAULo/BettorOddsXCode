//
//  BetModal.swift
//  BettorOdds
//
//  Version: 4.2.0 - Enhanced with exciting design and minimized info section
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
    
    // Enhanced animation states
    @State private var teamSelectionPulse = false
    @State private var inputGlow = false
    @State private var buttonBounce = false
    
    // Teal color definition for consistency
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    init(game: Game, user: User, isPresented: Binding<Bool>, preselectedTeam: String? = nil) {
        self.game = game
        self.user = user
        self._isPresented = isPresented
        self.preselectedTeam = preselectedTeam
        self._viewModel = StateObject(wrappedValue: BetModalViewModel(game: game, user: user))
        self._selectedTeam = State(initialValue: preselectedTeam)
    }
    
    var body: some View {
        ZStack {
            // Enhanced background with subtle animation
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.13, blue: 0.15),
                    Color(red: 0.13, green: 0.23, blue: 0.26),
                    Color(red: 0.17, green: 0.33, blue: 0.39)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .hueRotation(.degrees(teamSelectionPulse ? 5 : 0))
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: teamSelectionPulse)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // FIXED: Add proper safe area spacing for top
                Spacer()
                    .frame(height: 8)
                
                // MINIMIZED: Compact drag indicator
                dragIndicator
                
                // MINIMIZED: Super compact top section - OUTSIDE ScrollView to prevent clipping
                compactGameInfo
                    .padding(.bottom, 16)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // EXCITING: Enhanced team selection with colors & animations
                        excitingTeamSelection
                        
                        // Enhanced coin selection
                        enhancedCoinSelection
                        
                        // EXCITING: Enhanced bet amount input
                        excitingBetAmountInput
                        
                        // PROMINENT: Potential winnings display
                        prominentWinningsDisplay
                        
                        // EXCITING: Animated place bet button
                        excitingPlaceBetButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .alert("Bet Placed Successfully! 🎉", isPresented: $showSuccess) {
            Button("Awesome!") {
                isPresented = false
            }
        } message: {
            Text("Your bet has been placed and will be matched with another player. Good luck! 🍀")
        }
    }
    
    // MARK: - MINIMIZED: Compact Game Info with Date/Time
    
    private var compactGameInfo: some View {
        VStack(spacing: 6) {
            // Game matchup row
            HStack(spacing: 8) {
                // Super compact team display
                Text(game.awayTeam)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                
                Text(game.awaySpread)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(tealColor)
                
                Text("@")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 12, height: 12)
                    .background(Circle().fill(tealColor.opacity(0.3)))
                
                Text(game.homeSpread)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(tealColor)
                
                Text(game.homeTeam)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                
                Spacer()
                
                // Tiny league badge
                Text(game.league)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(tealColor.opacity(0.4)))
            }
            
            // Game date/time row
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 8))
                    .foregroundColor(tealColor)
                
                Text(formattedGameDateTime)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper for Game Date/Time Formatting
    
    private var formattedGameDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: game.time)
    }
    
    // MARK: - EXCITING: Enhanced Team Selection with Team Colors
    
    private var excitingTeamSelection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Choose Your Team")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Excitement indicator
                Image(systemName: "target")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(tealColor)
                    .scaleEffect(selectedTeam != nil ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTeam)
            }
            
            HStack(spacing: 20) {
                // Away team - Enhanced with team colors
                excitingTeamButton(
                    teamName: game.awayTeam,
                    spread: game.awaySpread,
                    isSelected: selectedTeam == game.awayTeam,
                    teamColors: game.awayTeamColors,
                    action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTeam = game.awayTeam
                        }
                        HapticManager.impact(.heavy)
                    }
                )
                
                // Home team - Enhanced with team colors
                excitingTeamButton(
                    teamName: game.homeTeam,
                    spread: game.homeSpread,
                    isSelected: selectedTeam == game.homeTeam,
                    teamColors: game.homeTeamColors,
                    action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTeam = game.homeTeam
                        }
                        HapticManager.impact(.heavy)
                    }
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Enhanced Team Button with Actual Team Colors
    
    private func excitingTeamButton(teamName: String, spread: String, isSelected: Bool, teamColors: TeamColors, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Team name with shadow
                Text(teamName)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                
                // Spread with team color styling
                Text(spread)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(teamColors.primary.opacity(0.4))
                            .overlay(
                                Capsule()
                                    .stroke(teamColors.primary, lineWidth: 2)
                            )
                    )
                    .shadow(color: teamColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                            // Use actual team colors when selected!
                            LinearGradient(
                                colors: [
                                    teamColors.primary.opacity(0.5),
                                    teamColors.secondary.opacity(0.3),
                                    teamColors.primary.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? teamColors.primary : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? teamColors.primary.opacity(0.4) : Color.black.opacity(0.1),
                        radius: isSelected ? 10 : 4,
                        x: 0,
                        y: isSelected ? 6 : 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
    
    // MARK: - Enhanced Coin Selection
    
    private var enhancedCoinSelection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Coin Type")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Current balance indicator
                HStack(spacing: 4) {
                    Image(systemName: viewModel.selectedCoinType == .yellow ? "circle.fill" : "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(viewModel.selectedCoinType == .yellow ? .yellow : tealColor)
                    
                    Text("Balance: \(viewModel.selectedCoinType == .yellow ? user.yellowCoins : user.greenCoins)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            HStack(spacing: 16) {
                // Yellow Coins
                coinTypeButton(
                    type: .yellow,
                    balance: user.yellowCoins,
                    isSelected: viewModel.selectedCoinType == .yellow,
                    action: { viewModel.selectedCoinType = .yellow }
                )
                
                // Green Coins (Real Money)
                coinTypeButton(
                    type: .green,
                    balance: user.greenCoins,
                    isSelected: viewModel.selectedCoinType == .green,
                    action: { viewModel.selectedCoinType = .green }
                )
            }
        }   
    }
    
    private func coinTypeButton(type: CoinType, balance: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Icon
                Group {
                    if type == .yellow {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(tealColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type == .yellow ? "Play Coins" : "Real Coins")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(balance)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                            LinearGradient(
                                colors: [tealColor.opacity(0.3), tealColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? tealColor.opacity(0.6) : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    // MARK: - EXCITING: Enhanced Bet Amount Input
    
    private var excitingBetAmountInput: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Bet Amount")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Quick bet suggestions
                HStack(spacing: 8) {
                    ForEach([5, 10, 25], id: \.self) { amount in
                        Button("\(amount)") {
                            viewModel.betAmount = "\(amount)"
                            HapticManager.impact(.light)
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(tealColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(tealColor.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(tealColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            
            // Enhanced input field
            TextField("Enter amount", text: $viewModel.betAmount)
                .keyboardType(.numberPad)
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            tealColor.opacity(inputGlow ? 0.8 : 0.4),
                                            tealColor.opacity(inputGlow ? 0.6 : 0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(
                            color: tealColor.opacity(inputGlow ? 0.3 : 0.1),
                            radius: inputGlow ? 12 : 6,
                            x: 0,
                            y: 4
                        )
                )
                .scaleEffect(inputGlow ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: inputGlow)
            
            // Validation message
            if let validationMessage = viewModel.validationMessage, !validationMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    
                    Text(validationMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - PROMINENT: Potential Winnings Display
    
    private var prominentWinningsDisplay: some View {
        VStack(spacing: 12) {
            Text("Potential Winnings")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                // Coin icon
                Group {
                    if viewModel.selectedCoinType == .yellow {
                        Text("🟡")
                            .font(.system(size: 24))
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(tealColor)
                    }
                }
                
                Text(viewModel.potentialWinnings)
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: tealColor.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Text("coins")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
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
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(tealColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - EXCITING: Animated Place Bet Button
    
    private var excitingPlaceBetButton: some View {
        Button(action: {
            Task {
                await placeBet()
            }
        }) {
            HStack(spacing: 12) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "target")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(isProcessing ? "Placing Bet..." : "Place Bet")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
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
                        color: viewModel.canPlaceBet && !isProcessing ? tealColor.opacity(0.4) : Color.clear,
                        radius: buttonBounce ? 16 : 8,
                        x: 0,
                        y: buttonBounce ? 8 : 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!viewModel.canPlaceBet || isProcessing)
        .scaleEffect(buttonBounce ? 1.05 : (viewModel.canPlaceBet && !isProcessing ? 1.0 : 0.95))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.canPlaceBet)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: buttonBounce)
    }
    
    // MARK: - Compact Drag Indicator
    
    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.white.opacity(0.3))
            .frame(width: 40, height: 6)
            .padding(.top, 4)
            .padding(.bottom, 8)
    }
    
    // MARK: - Animation Controls
    
    private func startAnimations() {
        teamSelectionPulse = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            inputGlow = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            buttonBounce = true
        }
    }
    
    // MARK: - Helper Functions
    
    private func placeBet() async {
        guard viewModel.canPlaceBet else { return }
        guard let selectedTeam = selectedTeam else { return }
        
        isProcessing = true
        
        let isHomeTeam = selectedTeam == game.homeTeam
        
        do {
            let success = try await viewModel.placeBet(team: selectedTeam, isHomeTeam: isHomeTeam)
            
            if success {
                showSuccess = true
                HapticManager.impact(.heavy)
            }
        } catch {
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
