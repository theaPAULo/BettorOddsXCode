//
//  AdminSections.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 1.0.0
//

import SwiftUI

// MARK: - Users Section
struct AdminUsersSection: View {
    let users: [User]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(users) { user in
                AdminUserRow(user: user)
            }
        }
    }
}

struct AdminUserRow: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.email)
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Text("Joined: \(user.dateJoined.formatted())")
                .font(.caption)
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 16) {
                CoinInfoView(emoji: "🟡", amount: user.yellowCoins)
                CoinInfoView(emoji: "💚", amount: user.greenCoins)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

// MARK: - Bets Section
struct AdminBetsSection: View {
    let bets: [Bet]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(bets) { bet in
                AdminBetRow(bet: bet)
            }
        }
    }
}

struct AdminBetRow: View {
    let bet: Bet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(bet.team)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text(bet.coinType.emoji + String(bet.amount))
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }
            
            HStack {
                Text(bet.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(bet.status.color.opacity(0.2))
                    .foregroundColor(bet.status.color)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(bet.createdAt.formatted())
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

// MARK: - Transactions Section
struct AdminTransactionsSection: View {
    let transactions: [Transaction]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(transactions) { transaction in
                AdminTransactionRow(transaction: transaction)
            }
        }
    }
}

struct AdminTransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(transaction.type.rawValue)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text(transaction.coinType.emoji + String(format: "%.2f", transaction.amount))
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }
            
            Text(transaction.createdAt.formatted())
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

struct CoinInfoView: View {
    let emoji: String
    let amount: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
            Text("\(amount)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textPrimary)
        }
    }
}
