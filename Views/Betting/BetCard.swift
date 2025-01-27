//
//  BetCard.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//


//
//  BetCard.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.0
//

import SwiftUI

struct BetCard: View {
    // MARK: - Properties
    let bet: Bet
    let onCancelTapped: () -> Void
    @State private var showCancelConfirmation = false
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status and Team Info
            HStack {
                StatusBadge(status: bet.status)
                Spacer()
                Text(bet.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            // Team and Spread
            VStack(alignment: .leading, spacing: 4) {
                Text(bet.team)
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Spread: \(String(format: "%.1f", bet.initialSpread))")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                if bet.currentSpread != bet.initialSpread {
                    Text("Current Spread: \(String(format: "%.1f", bet.currentSpread))")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
            }
            
            Divider()
            
            // Bet Amount and Potential Win
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bet Amount")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
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
                        .foregroundColor(.gray)
                    Text("\(bet.potentialWinnings)")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            
            // Cancel Button (only for pending bets)
            if bet.canBeCancelled {
                Button(action: {
                    showCancelConfirmation = true
                }) {
                    Text("Cancel Bet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .alert("Cancel Bet", isPresented: $showCancelConfirmation) {
            Button("Cancel Bet", role: .destructive) {
                onCancelTapped()
            }
            Button("Keep Bet", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this bet? This action cannot be undone.")
        }
    }
}

// MARK: - Status Badge Component
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

// MARK: - Preview Provider
#Preview {
    BetCard(
        bet: Bet(
            userId: "test",
            gameId: "1",
            coinType: .yellow,
            amount: 100,
            initialSpread: -5.5,
            team: "Lakers",
            isHomeTeam: true
        ),
        onCancelTapped: {}
    )
    .padding()
}
