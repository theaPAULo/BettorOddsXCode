import SwiftUI

struct BetCard: View {
    // MARK: - Properties
    let bet: Bet
    let onCancelTapped: () -> Void
    @State private var showCancelConfirmation = false
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status and Time Info
            HStack {
                StatusBadge(status: bet.status)
                Spacer()
                Text(bet.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.8))  // FIXED: Use .secondary instead
            }
            
            // Team and Spread
            VStack(alignment: .leading, spacing: 6) {  // Increased spacing
                Text(bet.team)
                    .font(.system(size: 18, weight: .semibold))  // Larger font
                    .foregroundColor(.primary)  // FIXED: Use .primary instead
                
                Text("Spread: \(String(format: "%.1f", bet.initialSpread))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)  // FIXED: Use .secondary instead
                
                if bet.currentSpread != bet.initialSpread {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)  // FIXED: Use .orange instead
                        Text("Current Spread: \(String(format: "%.1f", bet.currentSpread))")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)  // FIXED: Use .orange instead
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))  // FIXED: Use .gray instead
            
            // Bet Amount and Potential Win
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bet Amount")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)  // FIXED: Use .secondary instead
                    HStack {
                        Text(bet.coinType.emoji)
                        Text("\(bet.amount)")
                            .font(.system(size: 18, weight: .semibold))  // Larger font
                            .foregroundColor(.primary)  // FIXED: Use .primary instead
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Potential Win")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)  // FIXED: Use .secondary instead
                    Text("\(bet.potentialWinnings)")
                        .font(.system(size: 18, weight: .semibold))  // Larger font
                        .foregroundColor(bet.status == .won ? .green : .primary)  // FIXED: Use .green and .primary
                }
            }
            
            // Cancel Button (only for pending bets)
            if bet.canBeCancelled {
                Button(action: {
                    print("🎲 Cancel button pressed for bet: \(bet.id)")
                    showCancelConfirmation = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel Bet")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)  // FIXED: Use .red instead
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)  // Slightly taller
                    .background(Color.red.opacity(0.08))  // FIXED: Use .red instead
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)  // FIXED: Use .red instead
                    )
                }
                .buttonStyle(PlainButtonStyle())  // FIXED: Use PlainButtonStyle instead
            }
        }
        .padding()
        .background(
            Color(UIColor.secondarySystemBackground)  // FIXED: Use system color
                .opacity(0.95)  // Slightly transparent
        )
        .cornerRadius(16)  // Larger corner radius
        .shadow(
            color: Color.black.opacity(0.1),  // FIXED: Use .black instead
            radius: 8,
            x: 0,
            y: 4
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.1),  // FIXED: Use .gray instead
                            Color.gray.opacity(0.05)  // FIXED: Use .gray instead
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .alert("Cancel Bet", isPresented: $showCancelConfirmation) {
            Button("Keep Bet", role: .cancel) {
                print("❌ Cancellation cancelled")
            }
            Button("Cancel Bet", role: .destructive) {
                print("✅ User confirmed cancellation")
                onCancelTapped()
            }
        } message: {
            Text("Are you sure you want to cancel this bet? This action cannot be undone.")
                .foregroundColor(.primary)  // FIXED: Use .primary instead
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Background gradient
        LinearGradient(
            colors: [
                .primary.opacity(0.1),
                Color(UIColor.systemBackground),  // FIXED: Use system color
                .primary.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 16) {
                // Preview various bet states...
                Group {
                    // Pending bet
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
                    
                    // Won bet
                    BetCard(
                        bet: {
                            var bet = Bet(
                                userId: "test",
                                gameId: "2",
                                coinType: .green,
                                amount: 50,
                                initialSpread: 3.5,
                                team: "Warriors",
                                isHomeTeam: false
                            )
                            bet.status = .won
                            return bet
                        }(),
                        onCancelTapped: {}
                    )
                    
                    // Lost bet
                    BetCard(
                        bet: {
                            var bet = Bet(
                                userId: "test",
                                gameId: "3",
                                coinType: .yellow,
                                amount: 75,
                                initialSpread: 2.0,
                                team: "Celtics",
                                isHomeTeam: true
                            )
                            bet.status = .lost
                            return bet
                        }(),
                        onCancelTapped: {}
                    )
                }
            }
            .padding()
        }
    }
}
