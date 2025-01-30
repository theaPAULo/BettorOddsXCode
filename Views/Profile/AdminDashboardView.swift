//
//  AdminDashboardView.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 2.0.0
//

import SwiftUI
import FirebaseFirestore

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    @State private var selectedTab = AdminTab.overview
    
    // MARK: - Tab Enum
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
    
    // MARK: - Body
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
                        Task {
                            await viewModel.refreshData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppTheme.Brand.primary)
                    }
                }
                .padding()
                
                // Quick Actions Section
                VStack(spacing: 12) {
                    // Game Management Button
                    NavigationLink(destination: AdminGameManagementView()) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                            Text("Game Management")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.backgroundSecondary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                
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
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
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



// MARK: - Row Views
struct UserRow: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(user.email)
                .font(.headline)
            Text("Joined: \(user.dateJoined.formatted())")
                .font(.caption)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
}

struct BetRow: View {
    let bet: Bet
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(bet.team) - \(bet.amount) coins")
                .font(.headline)
            Text(bet.createdAt.formatted())
                .font(.caption)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(transaction.type.rawValue) - \(transaction.amount)")
                .font(.headline)
            Text(transaction.createdAt.formatted())
                .font(.caption)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview {
    AdminDashboardView()
}
