//
//  MyBetsView.swift
//  BettorOdds
//
//  Version: 2.1.0 - Conflict-free implementation with unique naming
//  Updated: June 2025

import SwiftUI

struct MyBetsView: View {
    @StateObject private var viewModel = EnhancedMyBetsViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedFilter: BetFilterType = .active
    @State private var showingWinStreak = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background gradient
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
                
                VStack(spacing: 0) {
                    // Header with stats
                    headerSection
                    
                    // Filter Tabs
                    filterSection
                    
                    // Content
                    contentSection
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadBets(for: authViewModel.user?.id ?? "")
            }
        }
        .refreshable {
            await viewModel.refreshBets(for: authViewModel.user?.id ?? "")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title and Stats Row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Bets")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let stats = viewModel.betStats {
                        Text("\(stats.totalBets) total • \(stats.winRate)% win rate")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Win Streak Indicator
                if let streak = viewModel.winStreak, streak > 0 {
                    winStreakIndicator(streak: streak)
                }
            }
            
            // Quick Stats Cards
            if let stats = viewModel.betStats {
                HStack(spacing: 12) {
                    BetStatCard(
                        title: "Won",
                        value: "\(stats.wonBets)",
                        color: Color.primary,
                        icon: "checkmark.circle.fill"
                    )
                    
                    BetStatCard(
                        title: "Lost",
                        value: "\(stats.lostBets)",
                        color: .red,
                        icon: "xmark.circle.fill"
                    )
                    
                    BetStatCard(
                        title: "Pending",
                        value: "\(stats.pendingBets)",
                        color: .orange,
                        icon: "clock.circle.fill"
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Win Streak Indicator
    
    private func winStreakIndicator(streak: Int) -> some View {
        HStack(spacing: 6) {
            if streak >= 3 {
                // Fire animation for hot streaks
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .scaleEffect(showingWinStreak ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: showingWinStreak)
            }
            
            Text("\(streak)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
                .font(.system(size: 16))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                )
        )
        .onAppear {
            if streak >= 3 {
                showingWinStreak = true
            }
        }
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        HStack(spacing: 0) {
            ForEach(BetFilterType.allCases, id: \.self) { filter in
                Button(action: { selectedFilter = filter }) {
                    Text(filter.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedFilter == filter ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Rectangle()
                                .fill(selectedFilter == filter ? Color.primary.opacity(0.8) : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if filteredBets.isEmpty {
                emptyStateView
            } else {
                betsListView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.primary))
                .scaleEffect(1.2)
            
            Text("Loading your bets...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.4))
            
            VStack(spacing: 8) {
                Text(selectedFilter == .active ? "No Active Bets" : "No \(selectedFilter.displayName) Bets")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(selectedFilter == .active ?
                     "Start betting on your favorite teams!" :
                     "Your \(selectedFilter.displayName.lowercased()) bets will appear here")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var betsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredBets) { bet in
                    MyBetCard(bet: bet)
                        .onTapGesture {
                            // TODO: Show bet details
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Bottom tab bar padding
        }
    }
    
    private var filteredBets: [Bet] {
        switch selectedFilter {
        case .active:
            return viewModel.bets.filter {
                $0.status == .pending ||
                $0.status == .partiallyMatched ||
                $0.status == .fullyMatched ||
                $0.status == .active
            }
        case .completed:
            return viewModel.bets.filter {
                $0.status == .won ||
                $0.status == .lost ||
                $0.status == .cancelled
            }
        case .all:
            return viewModel.bets
        }
    }
}

// MARK: - Supporting Views (Unique Names)

struct BetStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct MyBetCard: View {
    let bet: Bet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Row
            HStack {
                // Status Badge
                statusBadge
                
                Spacer()
                
                // Date
                Text(bet.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Team and Bet Info
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(bet.team)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Spread: \(bet.initialSpread > 0 ? "+" : "")\(bet.initialSpread, specifier: "%.1f")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(bet.coinType.emoji)
                            .font(.system(size: 16))
                        Text("\(bet.amount)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    if bet.status == .won {
                        Text("Won: \(bet.estimatedWinnings)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.primary)
                    }
                }
            }
            
            // Progress or Result
            if bet.status == .pending || bet.status == .partiallyMatched || bet.status == .fullyMatched || bet.status == .active {
                progressIndicator
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var statusBadge: some View {
        Text(bet.status.friendlyName)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor)
            )
    }
    
    private var statusColor: Color {
        switch bet.status {
        case .pending:
            return .orange
        case .partiallyMatched:
            return .yellow
        case .fullyMatched, .active:
            return .blue
        case .cancelled:
            return .gray
        case .won:
            return Color.primary
        case .lost:
            return .red
        }
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.primary))
                .scaleEffect(0.8)
            
            Text(bet.status == .pending ? "Finding match..." : "Game in progress")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
        }
    }
}

// MARK: - Enhanced ViewModel with Real Data

@MainActor
class EnhancedMyBetsViewModel: ObservableObject {
    @Published var bets: [Bet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var betStats: MyBetStats?
    @Published var winStreak: Int?
    
    private let betsManager = BetsManager.shared
    
    func loadBets(for userId: String) async {
        guard !userId.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            bets = try await betsManager.fetchBets()
            calculateStats()
            calculateWinStreak()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading bets: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshBets(for userId: String) async {
        await loadBets(for: userId)
    }
    
    private func calculateStats() {
        let totalBets = bets.count
        let wonBets = bets.filter { $0.status == .won }.count
        let lostBets = bets.filter { $0.status == .lost }.count
        let pendingBets = bets.filter {
            $0.status == .pending ||
            $0.status == .partiallyMatched ||
            $0.status == .fullyMatched ||
            $0.status == .active
        }.count
        
        let winRate = totalBets > 0 ? Int((Double(wonBets) / Double(totalBets)) * 100) : 0
        
        betStats = MyBetStats(
            totalBets: totalBets,
            wonBets: wonBets,
            lostBets: lostBets,
            pendingBets: pendingBets,
            winRate: winRate
        )
    }
    
    private func calculateWinStreak() {
        let completedBets = bets
            .filter { $0.status == .won || $0.status == .lost }
            .sorted { $0.createdAt > $1.createdAt }
        
        var currentStreak = 0
        for bet in completedBets {
            if bet.status == .won {
                currentStreak += 1
            } else {
                break
            }
        }
        
        winStreak = currentStreak
    }
}

// MARK: - Supporting Types (Unique Names)

enum BetFilterType: CaseIterable {
    case active, completed, all
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .all: return "All"
        }
    }
}

struct MyBetStats {
    let totalBets: Int
    let wonBets: Int
    let lostBets: Int
    let pendingBets: Int
    let winRate: Int
}

// MARK: - Extensions (Unique Names to Avoid Conflicts)

extension Bet {
    var estimatedWinnings: Int {
        // Simple calculation - can be enhanced
        return Int(Double(amount) * 1.9)
    }
}

extension BetStatus {
    var friendlyName: String {
        switch self {
        case .pending:
            return "Pending"
        case .partiallyMatched:
            return "Matching"
        case .fullyMatched:
            return "Matched"
        case .active:
            return "Active"
        case .cancelled:
            return "Cancelled"
        case .won:
            return "Won"
        case .lost:
            return "Lost"
        }
    }
}

#Preview {
    MyBetsView()
        .environmentObject(AuthenticationViewModel())
}
