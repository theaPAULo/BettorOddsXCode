//
//  AdminDashboardView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/29/25.
//


//
//  AdminDashboardView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/29/25.
//  Version: 1.0.0
//

import SwiftUI
import FirebaseFirestore

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    @State private var selectedTab = AdminTab.overview
    
    enum AdminTab {
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
                // Admin Header
                HStack {
                    Text("Admin Dashboard")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.Brand.primary)
                    Spacer()
                    Button(action: {
                        // Wrap the async call in a Task
                        Task {
                            await viewModel.refreshData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppTheme.Brand.primary)
                    }
                }
                .padding()
                // Tab Selection
                HStack(spacing: 0) {
                    ForEach([AdminTab.overview, .users, .bets, .transactions], id: \.self) { tab in
                        AdminTabButton(
                            title: tab.title,
                            icon: tab.icon,
                            isSelected: selectedTab == tab
                        ) {
                            withAnimation {
                                selectedTab = tab
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .overview:
                            AdminOverviewSection(stats: viewModel.stats)
                        case .users:
                            AdminUsersSection(users: viewModel.users)
                        case .bets:
                            AdminBetsSection(bets: viewModel.bets)
                        case .transactions:
                            AdminTransactionsSection(transactions: viewModel.transactions)
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            .navigationBarHidden(true)
        }
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
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 12))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? AppTheme.Brand.primary.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? AppTheme.Brand.primary : .gray)
        }
    }
}

struct AdminOverviewSection: View {
    let stats: AdminDashboardViewModel.DashboardStats
    
    var body: some View {
        VStack(spacing: 16) {
            // Quick Stats
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(title: "Active Users", value: "\(stats.activeUsers)")
                StatCard(title: "Daily Bets", value: "\(stats.dailyBets)")
                StatCard(title: "Revenue", value: "$\(stats.revenue)")
                StatCard(title: "Pending Bets", value: "\(stats.pendingBets)")
            }
            
            // Recent Activity
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Activity")
                    .font(.headline)
                
                ForEach(stats.recentActivity, id: \.id) { activity in
                    HStack {
                        Circle()
                            .fill(activity.type.color)
                            .frame(width: 8, height: 8)
                        Text(activity.description)
                            .font(.system(size: 14))
                        Spacer()
                        Text(activity.time)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 24, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// Preview provider
#Preview {
    AdminDashboardView()
}
