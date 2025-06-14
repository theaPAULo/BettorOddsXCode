//
//  AdminDashboardView.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 2.4.0 - Simplified to fix Swift compiler issue
//

import SwiftUI
import FirebaseFirestore

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    @State private var selectedTab = AdminTab.overview
    
    // MARK: - Tab Enum
    enum AdminTab: CaseIterable {
        case overview
        case users
        case bets
        case transactions
        
        var title: String {
            switch self {
            case .overview: return "Overview"
            case .users: return "Users"
            case .bets: return "Bets"
            case .transactions: return "Transactions"
            }
        }
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .users: return "person.2.fill"
            case .bets: return "dollarsign.circle.fill"
            case .transactions: return "arrow.left.arrow.right"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Tab Selection
                tabSelectionSection
                
                // Content
                contentSection
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Text("Admin Dashboard")
                .font(AppTheme.Typography.largeTitle)
                .foregroundColor(AppTheme.Colors.primary)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.refreshData()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.md)
    }
    
    // MARK: - Tab Selection Section
    
    private var tabSelectionSection: some View {
        HStack(spacing: 0) {
            ForEach(AdminTab.allCases, id: \.self) { tab in
                AdminTabButton(
                    title: tab.title,
                    icon: tab.icon,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Switch on selected tab
                Group {
                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .users:
                        usersContent
                    case .bets:
                        betsContent
                    case .transactions:
                        transactionsContent
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    // MARK: - Content Views
    
    private var overviewContent: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Dashboard Overview")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            if viewModel.stats.activeUsers > 0 {
                VStack(spacing: AppTheme.Spacing.sm) {
                    HStack {
                        StatCardView(title: "Active Users", value: "\(viewModel.stats.activeUsers)", color: .blue)
                        StatCardView(title: "Daily Bets", value: "\(viewModel.stats.dailyBets)", color: .green)
                    }
                    
                    HStack {
                        StatCardView(title: "Revenue", value: String(format: "%.2f", viewModel.stats.revenue), color: .orange)
                        StatCardView(title: "Pending", value: "\(viewModel.stats.pendingBets)", color: .red)
                    }
                }
            } else {
                Text("Loading statistics...")
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
    
    private var usersContent: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Users Management")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("User management functionality")
                .font(AppTheme.Typography.callout)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
    
    private var betsContent: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Bets Management")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Bet monitoring functionality")
                .font(AppTheme.Typography.callout)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
    
    private var transactionsContent: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Transactions Management")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Transaction monitoring functionality")
                .font(AppTheme.Typography.callout)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
}

// MARK: - Supporting Views

struct AdminTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(AppTheme.Typography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(isSelected ? AppTheme.Colors.primary.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(value)
                .font(AppTheme.Typography.title2)
                .foregroundColor(color)
                .fontWeight(.bold)
            
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(Color.white.opacity(0.05))
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

#Preview {
    AdminDashboardView()
}
