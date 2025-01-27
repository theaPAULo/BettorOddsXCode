//
//  BetModal.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 2.0.1
//

import SwiftUI

struct BetModal: View {
    // MARK: - Properties
    let game: Game
    @Binding var isPresented: Bool
    @StateObject private var viewModel: BetModalViewModel
    @State private var selectedTeam: String?
    @State private var isHomeTeamSelected: Bool = false
    
    // MARK: - Initialization
    init(game: Game, user: User, isPresented: Binding<Bool>) {
        self.game = game
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: BetModalViewModel(game: game, user: user))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Game Info Section
                    gameInfoSection
                    
                    // Team Selection
                    teamSelectionSection
                    
                    // Coin Type Selection
                    coinTypeSection
                    
                    // Bet Amount Section
                    betAmountSection
                    
                    // Potential Winnings
                    potentialWinningsSection
                    
                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(AppTheme.Status.error)
                            .font(.system(size: 14))
                    }
                    
                    // Place Bet Button
                    placeBetButton
                }
                .padding()
            }
            .background(AppTheme.Background.primary)
            .navigationTitle("Place Bet")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: closeButton)
        }
    }
    
    // MARK: - UI Components
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
    
    private func teamButton(team: String, spread: Double, isSelected: Bool, isHome: Bool) -> some View {
        Button(action: {
            selectedTeam = team
            isHomeTeamSelected = isHome
        }) {
            VStack(spacing: 8) {
                Text(team)
                    .font(.system(size: 16, weight: .medium))
                Text(spread > 0 ? "+\(String(format: "%.1f", spread))" : "\(String(format: "%.1f", spread))")
                    .font(.system(size: 14))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? AppTheme.Brand.primary.opacity(0.1) : AppTheme.Background.card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.Brand.primary : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isSelected ? AppTheme.Brand.primary : AppTheme.Text.primary)
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
    
    private var placeBetButton: some View {
        Button(action: {
            guard let team = selectedTeam else { return }
            Task {
                let success = try? await viewModel.placeBet(team: team, isHomeTeam: isHomeTeamSelected)
                if success == true {
                    isPresented = false
                }
            }
        }) {
            if viewModel.isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("Place Bet")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(viewModel.canPlaceBet && selectedTeam != nil ? AppTheme.Brand.primary : AppTheme.Text.secondary)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(!viewModel.canPlaceBet || selectedTeam == nil || viewModel.isProcessing)
    }
    
    private var closeButton: some View {
        Button("Close") {
            isPresented = false
        }
    }
}
