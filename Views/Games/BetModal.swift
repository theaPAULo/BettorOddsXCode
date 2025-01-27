//
//  BetModal.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 2.3.0

import SwiftUI

struct BetModal: View {
    // MARK: - Properties
    let game: Game
    let user: User
    let preSelectedTeam: TeamSelection?
    @Binding var isPresented: Bool
    @StateObject private var viewModel: BetModalViewModel
    @State private var selectedTeam: TeamSelection?
    @State private var showConfirmation = false
    @State private var showBiometricAuth = false
    @State private var showToast = false
    
    // Gradient opacities
    private let defaultOpacity: Double = 0.08
    private let selectedOpacity: Double = 0.2
    
    // MARK: - Initialization
    init(game: Game, user: User, isPresented: Binding<Bool>, preSelectedTeam: TeamSelection?) {
        self.game = game
        self.user = user
        self._isPresented = isPresented
        self.preSelectedTeam = preSelectedTeam
        self._viewModel = StateObject(wrappedValue: BetModalViewModel(game: game, user: user))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Balance Header
                balanceHeader
                
                // Game Info Section
                VStack(spacing: 8) {
                    Text("\(game.awayTeam) @ \(game.homeTeam)")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text(game.formattedTime)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.Background.card)
                .cornerRadius(12)
                
                // Team Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Team")
                        .font(.headline)
                    
                    HStack(spacing: 0) {
                        // Away Team Button
                        Button(action: { selectedTeam = .away }) {
                            VStack(spacing: 8) {
                                Text(game.awayTeam)
                                    .font(.system(size: 16, weight: .medium))
                                Text(game.awaySpread)
                                    .font(.system(size: 20, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(game.awayTeamColors.primary)
                        }
                        .background(
                            LinearGradient(
                                colors: [
                                    game.awayTeamColors.primary.opacity(selectedTeam == .away ? selectedOpacity : defaultOpacity),
                                    game.awayTeamColors.primary.opacity(selectedTeam == .away ? selectedOpacity * 0.7 : defaultOpacity * 0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        
                        Text("@")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .frame(width: 40)
                            .background(Color(.systemBackground))
                        
                        // Home Team Button
                        Button(action: { selectedTeam = .home }) {
                            VStack(spacing: 8) {
                                Text(game.homeTeam)
                                    .font(.system(size: 16, weight: .medium))
                                Text(game.homeSpread)
                                    .font(.system(size: 20, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(game.homeTeamColors.primary)
                        }
                        .background(
                            LinearGradient(
                                colors: [
                                    game.homeTeamColors.primary.opacity(selectedTeam == .home ? selectedOpacity * 0.7 : defaultOpacity * 0.7),
                                    game.homeTeamColors.primary.opacity(selectedTeam == .home ? selectedOpacity : defaultOpacity)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                    .cornerRadius(12)
                }
                
                // Bet Options Section
                VStack(spacing: 16) {
                    // Coin Type Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Coin Type")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            coinTypeButton(type: .yellow)
                            coinTypeButton(type: .green)
                        }
                    }
                    
                    // Bet Amount and Potential Winnings side by side
                    HStack(spacing: 16) {
                        // Bet Amount Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bet Amount")
                                .font(.headline)
                            
                            HStack {
                                Text(viewModel.selectedCoinType.emoji)
                                    .font(.system(size: 24))
                                TextField("0", text: $viewModel.betAmount)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Potential Winnings
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Potential Win")
                                .font(.headline)
                            
                            HStack {
                                Text(viewModel.selectedCoinType.emoji)
                                    .font(.system(size: 24))
                                Text("\(viewModel.potentialWinnings)")
                                    .font(.system(size: 20, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Daily Limit (if green coins)
                if viewModel.selectedCoinType == .green {
                    Text("Daily Limit: \(viewModel.remainingDailyLimit) coins")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                // Validation Messages
                validationMessages
                    .padding(.horizontal)
                
                Spacer()
                
                // Place Bet Button
                CustomButton(
                    title: viewModel.isProcessing ? "Processing..." : "Place Bet",
                    action: { showConfirmation = true },
                    isLoading: viewModel.isProcessing,
                    disabled: !canPlaceBet
                )
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Place Bet")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: closeButton)
            .overlay(toastOverlay)
            // Rest of the modifiers (confirmation dialog, etc.) remain the same
            .onAppear {
                selectedTeam = preSelectedTeam
            }
        }
    }
    
    // MARK: - Supporting Views
    
    private var closeButton: some View {
        Button("Close") {
            isPresented = false
        }
    }
    
    private var balanceHeader: some View {
        HStack {
            // Yellow Coins
            HStack(spacing: 4) {
                Text("🟡")
                    .font(.system(size: 24))
                Text("\(user.yellowCoins)")
                    .font(.system(size: 16, weight: .bold))
            }
            
            Spacer()
            
            // Green Coins
            HStack(spacing: 4) {
                Text("💚")
                    .font(.system(size: 24))
                Text("\(user.greenCoins)")
                    .font(.system(size: 16, weight: .bold))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(AppTheme.Background.card)
        .cornerRadius(12)
    }
    
    private var validationMessages: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let amount = Int(viewModel.betAmount) {
                if amount <= 0 {
                    ValidationMessage("Bet amount must be greater than 0", type: .error)
                }
                
                if viewModel.selectedCoinType == .green {
                    if amount > viewModel.remainingDailyLimit {
                        ValidationMessage("Exceeds daily limit of 100 green coins", type: .error)
                    } else if Double(amount) > Double(viewModel.remainingDailyLimit) * 0.8 {
                        ValidationMessage("Approaching daily limit", type: .warning)
                    }
                    
                    if amount > user.greenCoins {
                        ValidationMessage("Insufficient green coins", type: .error)
                    }
                } else {
                    if amount > user.yellowCoins {
                        ValidationMessage("Insufficient yellow coins", type: .error)
                    }
                }
            }
            
            if selectedTeam == nil {
                ValidationMessage("Select a team to bet on", type: .info)
            }
        }
        .padding(.horizontal)
    }
    
    private var toastOverlay: some View {
        VStack {
            if showToast {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                    Text("Bet Placed Successfully!")
                        .font(.headline)
                    Text("Redirecting to My Bets...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: showToast)
        .zIndex(1)
    }
    
    private func coinTypeButton(type: CoinType) -> some View {
        Button(action: {
            viewModel.selectedCoinType = type
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            HStack {
                Text(type.emoji)
                    .font(.system(size: 24))
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
    
    // MARK: - Computed Properties
    
    private var canPlaceBet: Bool {
        guard selectedTeam != nil,
              !viewModel.betAmount.isEmpty,
              let amount = Int(viewModel.betAmount),
              amount > 0
        else { return false }
        
        if viewModel.selectedCoinType == .green {
            return amount <= viewModel.remainingDailyLimit && amount <= user.greenCoins
        }
        
        return amount <= user.yellowCoins
    }
    
    // MARK: - Methods
    
    private func handlePlaceBet() {
        guard let team = selectedTeam else { return }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        Task {
            if let success = try? await viewModel.placeBet(
                team: team == .home ? game.homeTeam : game.awayTeam,
                isHomeTeam: team == .home
            ) {
                if success {
                    withAnimation {
                        generator.impactOccurred()
                        showToast = true
                        
                        // Hide toast after delay and navigate
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showToast = false
                                // Navigate to My Bets and dismiss modal
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("NavigateToMyBets"),
                                    object: nil
                                )
                                isPresented = false
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Structs

struct ValidationMessage: View {
    let message: String
    let type: ValidationType
    
    enum ValidationType {
        case error, warning, info
        
        var color: Color {
            switch self {
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .error: return "exclamationmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    init(_ message: String, type: ValidationType) {
        self.message = message
        self.type = type
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(type.color)
        }
    }
}

#Preview {
    BetModal(
        game: Game.sampleGames[0],
        user: User(id: "test", email: "test@example.com"),
        isPresented: .constant(true),
        preSelectedTeam: .home
    )
}
