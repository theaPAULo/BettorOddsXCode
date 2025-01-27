//
//  MyBetsView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//

import SwiftUI

// MARK: - Models
struct Bet: Identifiable {
    let id: String
    let game: String
    let amount: Int
    let coinType: CoinType  // Using the existing CoinType from Models/CoinType.swift
    let potentialWin: Int
    let status: BetStatus
}

enum BetStatus: String {
    case active = "Active"
    case won = "Won"
    case lost = "Lost"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .active:
            return .blue
        case .won:
            return .green
        case .lost:
            return .red
        case .cancelled:
            return .gray
        }
    }
}

// MARK: - Views
struct MyBetsView: View {
    @State private var selectedFilter = BetFilter.active
    @State private var isRefreshing = false
    
    enum BetFilter: String, CaseIterable {
        case active = "Active"
        case completed = "Completed"
        case all = "All"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(BetFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Bets List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(sampleBets) { bet in
                        BetCard(bet: bet)
                    }
                }
                .padding()
            }
            .refreshable {
                // Add refresh logic here
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                isRefreshing = false
            }
        }
        .navigationTitle("My Bets")
    }
}

struct BetCard: View {
    let bet: Bet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Game Info
            HStack {
                Text(bet.game)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                StatusBadge(status: bet.status)
            }
            
            Divider()
            
            // Bet Details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bet Amount")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                    HStack {
                        Text(bet.coinType.emoji)
                        Text("\(bet.amount)")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Potential Win")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("\(bet.potentialWin)")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct StatusBadge: View {
    let status: BetStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(8)
    }
}

// Sample data
let sampleBets = [
    Bet(id: "1", game: "Lakers vs Warriors", amount: 100, coinType: .yellow, potentialWin: 190, status: .active),
    Bet(id: "2", game: "Chiefs vs Bills", amount: 50, coinType: .green, potentialWin: 95, status: .won),
    // Add more sample bets
]

#Preview {
    NavigationView {
        MyBetsView()
    }
}
