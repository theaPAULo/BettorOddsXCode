//
//  EnhancedBetModalView.swift
//  BettorOdds
//
//  Created by Claude on 6/13/25
//  Version: 2.0.0 - Modern design with swipe-to-dismiss and better UX
//

import SwiftUI

struct EnhancedBetModalView: View {
    let game: Game
    let user: User
    @Binding var isPresented: Bool
    
    @StateObject private var viewModel: BetModalViewModel
    @State private var selectedTeam: String = ""
    @State private var isHomeTeam: Bool = false
    @State private var showKeypad = false
    @State private var dragOffset: CGSize = .zero
    @State private var showSuccessAnimation = false
    
    // Animation states
    @State private var contentOpacity: Double = 0
    @State private var contentScale: Double = 0.9
    
    init(game: Game, user: User, isPresented: Binding<Bool>) {
        self.game = game
        self.user = user
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: BetModalViewModel(game: game, user: user))
    }
    
    var body: some View {
        ZStack {
            // Background with blur
            AppTheme.Colors.background.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Modal Content
            VStack(spacing: 0) {
                // Drag Handle
                dragHandle
                
                // Modal Card
                modalCard
            }
            .offset(y: dragOffset.height)
            .scaleEffect(contentScale)
            .opacity(contentOpacity)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 150 || value.predictedEndTranslation.height > 300 {
                            dismiss()
                        } else {
                            withAnimation(AppTheme.Animation.spring) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
            
            // Success Animation Overlay
            if showSuccessAnimation {
                successOverlay
            }
        }
        .onAppear {
            withAnimation(AppTheme.Animation.spring) {
                contentOpacity = 1.0
                contentScale = 1.0
            }
        }
        .onChange(of: viewModel.showSuccess) { _, newValue in
            if newValue {
                showSuccessState()
            }
        }
        .errorHandling(viewModel: viewModel)
    }
    
    // MARK: - Drag Handle
    
    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(AppTheme.Colors.textTertiary)
            .frame(width: 40, height: 6)
            .padding(.top, AppTheme.Spacing.md)
    }
    
    // MARK: - Modal Card
    
    private var modalCard: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Header with close button and game info
            headerSection
            
            // Team Selection
            teamSelectionSection
            
            // Coin Type Selection
            coinTypeSection
            
            // Bet Amount Section
            betAmountSection
            
            // Potential Winnings
            potentialWinningsSection
            
            // Place Bet Button
            placeBetButton
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.xlarge, corners: [.topLeft, .topRight])
        .shadow(
            color: AppTheme.Shadow.large.color,
            radius: AppTheme.Shadow.large.radius,
            x: AppTheme.Shadow.large.x,
            y: AppTheme.Shadow.large.y
        )
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                // Themed close button (no more blue!)
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
                .hapticFeedback(.light)
                
                Spacer()
                
                // Game time and date (better placement)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(game.time.formatted(date: .abbreviated, time: .omitted))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Text(game.time.formatted(date: .omitted, time: .shortened))
                        .font(AppTheme.Typography.callout)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fontWeight(.semibold)
                }
            }
            
            // Enhanced title
            Text("Place Your Bet")
                .font(AppTheme.Typography.largeTitle)
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
    }
    
    // MARK: - Team Selection
    
    private var teamSelectionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Select Team")
                .font(AppTheme.Typography.title2)
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            HStack(spacing: AppTheme.Spacing.md) {
                // Away Team
                teamSelectionCard(
                    team: game.awayTeam,
                    spread: game.awaySpread,
                    isSelected: selectedTeam == game.awayTeam,
                    isHome: false
                )
                
                // Home Team
                teamSelectionCard(
                    team: game.homeTeam,
                    spread: game.homeSpread,
                    isSelected: selectedTeam == game.homeTeam,
                    isHome: true
                )
            }
        }
    }
    
    private func teamSelectionCard(team: String, spread: String, isSelected: Bool, isHome: Bool) -> some View {
        Button(action: {
            HapticManager.selection()
            withAnimation(AppTheme.Animation.springQuick) {
                selectedTeam = team
                isHomeTeam = isHome
            }
        }) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(team)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(spread)
                    .font(AppTheme.Typography.amount)
                    .foregroundColor(AppTheme.Colors.primary)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(isSelected ? AppTheme.Colors.primary.opacity(0.2) : AppTheme.Colors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .stroke(
                                isSelected ? AppTheme.Colors.primary : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(AppTheme.Animation.springQuick, value: isSelected)
    }
    
    // MARK: - Coin Type Selection
    
    private var coinTypeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Select Coin Type")
                .font(AppTheme.Typography.title2)
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            HStack(spacing: AppTheme.Spacing.md) {
                // Yellow Coins
                coinTypeCard(
                    coinType: .yellow,
                    emoji: "💛",
                    title: "Play Coins",
                    balance: user.yellowCoins,
                    isSelected: viewModel.selectedCoinType == .yellow
                )
                
                // Green Coins
                coinTypeCard(
                    coinType: .green,
                    emoji: "💚",
                    title: "Real Coins",
                    balance: user.greenCoins,
                    isSelected: viewModel.selectedCoinType == .green
                )
            }
        }
    }
    
    private func coinTypeCard(coinType: CoinType, emoji: String, title: String, balance: Int, isSelected: Bool) -> some View {
        Button(action: {
            HapticManager.selection()
            withAnimation(AppTheme.Animation.springQuick) {
                viewModel.selectedCoinType = coinType
            }
        }) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(emoji)
                    .font(.title)
                
                Text(title)
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                
                Text("Balance: \(balance)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(isSelected ? coinType == .yellow ? AppTheme.Colors.yellowCoin.opacity(0.2) : AppTheme.Colors.greenCoin.opacity(0.2) : AppTheme.Colors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .stroke(
                                isSelected ? (coinType == .yellow ? AppTheme.Colors.yellowCoin : AppTheme.Colors.greenCoin) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(AppTheme.Animation.springQuick, value: isSelected)
    }
    
    // MARK: - Bet Amount Section
    
    private var betAmountSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Bet Amount")
                .font(AppTheme.Typography.title2)
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            // Amount Input with enhanced styling
            HStack {
                Text(viewModel.coinTypeEmoji)
                    .font(.title2)
                
                TextField("0", text: $viewModel.betAmount)
                    .font(AppTheme.Typography.amountLarge)
                    .foregroundColor(.white)
                    .keyboardType(.numberPad)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onTapGesture {
                        showKeypad = true
                    }
                    .focused($showKeypad)
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
            
            // Validation message
            if let validationMessage = viewModel.validationMessage {
                Text(validationMessage)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.error)
            }
            
            // Daily limit for green coins
            if viewModel.selectedCoinType == .green {
                Text("Daily limit: \(user.dailyGreenCoinsUsed)/\(Configuration.Settings.dailyGreenCoinLimit)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Potential Winnings
    
    private var potentialWinningsSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("Potential Winnings")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            HStack {
                Text(viewModel.coinTypeEmoji)
                    .font(.title)
                Text(viewModel.potentialWinnings)
                    .font(AppTheme.Typography.amountLarge)
                    .foregroundColor(AppTheme.Colors.success)
                    .fontWeight(.bold)
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.success.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(AppTheme.Colors.success.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Place Bet Button
    
    private var placeBetButton: some View {
        Button(action: {
            placeBet()
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Place Bet")
                        .font(AppTheme.Typography.buttonLarge)
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(viewModel.canPlaceBet ? AppTheme.Colors.primary : AppTheme.Colors.buttonBackgroundDisabled)
            )
            .foregroundColor(.white)
        }
        .disabled(!viewModel.canPlaceBet || viewModel.isLoading)
        .scaleEffect(viewModel.canPlaceBet ? 1.0 : 0.98)
        .animation(AppTheme.Animation.springQuick, value: viewModel.canPlaceBet)
        .hapticFeedback(.medium)
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        ZStack {
            AppTheme.Colors.background.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.xl) {
                // Success animation
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.Colors.success)
                    .scaleEffect(showSuccessAnimation ? 1.0 : 0.1)
                    .animation(AppTheme.Animation.bounce, value: showSuccessAnimation)
                
                Text("Bet Placed Successfully!")
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .opacity(showSuccessAnimation ? 1.0 : 0)
                    .animation(AppTheme.Animation.standard.delay(0.2), value: showSuccessAnimation)
                
                Button("Continue") {
                    dismiss()
                }
                .primaryButtonStyle()
                .opacity(showSuccessAnimation ? 1.0 : 0)
                .animation(AppTheme.Animation.standard.delay(0.4), value: showSuccessAnimation)
            }
        }
    }
    
    // MARK: - Methods
    
    private func dismiss() {
        HapticManager.impact(.light)
        showKeypad = false // Dismiss keyboard
        
        withAnimation(AppTheme.Animation.standard) {
            contentOpacity = 0
            contentScale = 0.9
            dragOffset = CGSize(width: 0, height: 500)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    private func placeBet() {
        guard !selectedTeam.isEmpty else { return }
        
        HapticManager.impact(.medium)
        
        Task {
            let success = await viewModel.placeBet(team: selectedTeam, isHomeTeam: isHomeTeam)
            if success {
                HapticManager.notification(.success)
            } else {
                HapticManager.notification(.error)
            }
        }
    }
    
    private func showSuccessState() {
        withAnimation(AppTheme.Animation.spring) {
            showSuccessAnimation = true
        }
        
        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dismiss()
        }
    }
}

// MARK: - View Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func focused(_ condition: FocusState<Bool>.Binding) -> some View {
        self.focused(condition)
    }
}
