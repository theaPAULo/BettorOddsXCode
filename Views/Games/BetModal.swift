//
//  BetModal.swift
//  BettorOdds
//
//  Version: 3.1.0 - Redesigned with larger team selection and cleaner UI
//  Updated: June 2025

import Foundation
import SwiftUI

struct BetModal: View {
    let game: Game
    let user: User
    @Binding var isPresented: Bool
    let preselectedTeam: String?
    
    // ViewModel for proper bet management
    @StateObject private var viewModel: BetModalViewModel
    
    // Local UI state
    @State private var selectedTeam: String = ""
    @State private var isHomeTeam: Bool = false
    @State private var showSuccess = false
    @State private var showError = false
    
    // Theme colors
    private let tealColor = Color(red: 0.2, green: 0.8, blue: 0.8)
    
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
                // Background gradient matching Games view
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        compactGameHeader
                        largeTeamSelectionArea
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
                        print("🔄 Cancel button tapped")
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
            .navigationBarBackButtonHidden(true)
        }
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK") {
                print("🎉 Success acknowledged, dismissing modal")
                isPresented = false
            }
        } message: {
            Text("Your bet has been placed successfully!")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
                viewModel.validationMessage = nil
            }
        } message: {
            Text(viewModel.validationMessage ?? "An error occurred")
        }
        .onChange(of: viewModel.showSuccess) { success in
            showSuccess = success
        }
        .onChange(of: viewModel.validationMessage) { message in
            showError = message != nil
        }
        .onAppear {
            // Set preselected team if provided
            if let preselected = preselectedTeam {
                selectedTeam = preselected
                isHomeTeam = (preselected == game.homeTeam)
            }
        }
    }
    
    // MARK: - Compact Game Header (Much Smaller)
    
    private var compactGameHeader: some View {
        VStack(spacing: 4) {
            Text("\(game.awayTeam) @ \(game.homeTeam)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            HStack {
                Text(game.time.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text(game.league)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Large Team Selection Area (Main Focus)
    
    private var largeTeamSelectionArea: some View {
        VStack(spacing: 16) {
            Text("Choose Your Team")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            // Large Connected Team Cards (No Gap)
            HStack(spacing: 0) {
                // Away Team Button
                Button(action: {
                    selectedTeam = game.awayTeam
                    isHomeTeam = false
                }) {
                    VStack(spacing: 8) {
                        Text(shortTeamName(game.awayTeam))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 8)
                        
                        Text("\(awaySpread > 0 ? "+" : "")\(String(format: "%.1f", awaySpread))")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .background(awayTeamBackground)
                    .overlay(awayTeamBorder)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Home Team Button (Touching)
                Button(action: {
                    selectedTeam = game.homeTeam
                    isHomeTeam = true
                }) {
                    VStack(spacing: 8) {
                        Text(shortTeamName(game.homeTeam))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 8)
                        
                        Text("\(homeSpread > 0 ? "+" : "")\(String(format: "%.1f", homeSpread))")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .background(homeTeamBackground)
                    .overlay(homeTeamBorder)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                // Central divider line
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1)
                    .overlay(
                        Circle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("@")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
        }
    }
    
    // MARK: - Helper function for team names
    
    private func shortTeamName(_ fullName: String) -> String {
        // Handle long team names
        switch fullName {
        case "Oklahoma City Thunder":
            return "Oklahoma City\nThunder"
        case "Los Angeles Lakers", "Los Angeles Clippers", "Los Angeles Rams", "Los Angeles Chargers":
            return fullName.replacingOccurrences(of: "Los Angeles ", with: "LA ")
        case "Golden State Warriors":
            return "Golden State\nWarriors"
        case "Portland Trail Blazers":
            return "Portland\nTrail Blazers"
        case "New Orleans Saints", "New Orleans Pelicans":
            return fullName.replacingOccurrences(of: "New Orleans ", with: "New Orleans\n")
        case "New York Giants", "New York Jets", "New York Knicks", "New York Rangers":
            return fullName.replacingOccurrences(of: "New York ", with: "NY ")
        case "Tampa Bay Buccaneers", "Tampa Bay Lightning":
            return fullName.replacingOccurrences(of: "Tampa Bay ", with: "Tampa Bay\n")
        case "San Francisco 49ers":
            return "San Francisco\n49ers"
        case "Green Bay Packers":
            return "Green Bay\nPackers"
        default:
            // Split long names automatically
            let words = fullName.components(separatedBy: " ")
            if words.count >= 3 && fullName.count > 15 {
                let midPoint = words.count / 2
                let firstLine = words[0..<midPoint].joined(separator: " ")
                let secondLine = words[midPoint...].joined(separator: " ")
                return "\(firstLine)\n\(secondLine)"
            }
            return fullName
        }
    }
    
    // MARK: - Team Selection Backgrounds & Borders
    
    private var awayTeamBackground: some View {
        let isSelected = selectedTeam == game.awayTeam
        let teamColors = TeamColors.getTeamColors(game.awayTeam)
        
        return LinearGradient(
            colors: [
                teamColors.primary.opacity(isSelected ? 1.0 : 0.8),
                teamColors.primary.opacity(isSelected ? 0.9 : 0.7),
                teamColors.secondary.opacity(isSelected ? 0.8 : 0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Darker overlay when selected
            Color.black.opacity(isSelected ? 0.2 : 0.0)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var homeTeamBackground: some View {
        let isSelected = selectedTeam == game.homeTeam
        let teamColors = TeamColors.getTeamColors(game.homeTeam)
        
        return LinearGradient(
            colors: [
                teamColors.primary.opacity(isSelected ? 1.0 : 0.8),
                teamColors.primary.opacity(isSelected ? 0.9 : 0.7),
                teamColors.secondary.opacity(isSelected ? 0.8 : 0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Darker overlay when selected
            Color.black.opacity(isSelected ? 0.2 : 0.0)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var awayTeamBorder: some View {
        let isSelected = selectedTeam == game.awayTeam
        return Rectangle()
            .stroke(
                isSelected ? tealColor : Color.clear,
                lineWidth: isSelected ? 4 : 0
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var homeTeamBorder: some View {
        let isSelected = selectedTeam == game.homeTeam
        return Rectangle()
            .stroke(
                isSelected ? tealColor : Color.clear,
                lineWidth: isSelected ? 4 : 0
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    // MARK: - Coin Type Section (Streamlined)
    
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
                            .frame(width: 24, height: 24)
                        
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
                
                // Green Coins
                Button(action: {
                    viewModel.selectedCoinType = .green
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        
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
                    
                    Text("💚 \(viewModel.remainingDailyLimit)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
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
    
    // MARK: - Bet Amount Section (Simplified)
    
    private var betAmountSection: some View {
        VStack(spacing: 12) {
            TextField("Enter amount", text: $viewModel.betAmount)
                .keyboardType(.numberPad)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(16)
                .background(betAmountFieldBackground)
            
            if let message = viewModel.validationMessage {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
            }
        }
    }
    
    private var betAmountFieldBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    // MARK: - Potential Winnings (Compact)
    
    private var potentialWinningsSection: some View {
        HStack {
            Text("Win:")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(viewModel.coinTypeEmoji)
                    .font(.system(size: 20))
                
                Text(viewModel.potentialWinnings)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tealColor.opacity(0.3), lineWidth: 1)
                )
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
            .frame(height: 56)
            .background(placeBetButtonBackground)
        }
        .disabled(!viewModel.canPlaceBet || viewModel.isProcessing || selectedTeam.isEmpty)
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(viewModel.canPlaceBet && !viewModel.isProcessing && !selectedTeam.isEmpty ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.canPlaceBet)
    }
    
    private var placeBetButtonBackground: some View {
        let canPlace = viewModel.canPlaceBet && !viewModel.isProcessing && !selectedTeam.isEmpty
        
        return RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: canPlace ?
                        [tealColor, tealColor.opacity(0.8)] :
                        [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(
                color: canPlace ? tealColor.opacity(0.4) : Color.clear,
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
        
        print("🎯 Placing bet: \(selectedTeam), amount: \(viewModel.betAmount)")
        
        do {
            let success = try await viewModel.placeBet(team: selectedTeam, isHomeTeam: isHomeTeam)
            print("✅ Bet placement result: \(success)")
            
            if success {
                print("🎉 Showing success alert")
                showSuccess = true
                
                // Auto-dismiss after showing success
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    print("🔄 Auto-dismissing modal")
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
        isPresented: .constant(true),
        preselectedTeam: Game.sampleGames[0].homeTeam
    )
}
