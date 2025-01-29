import SwiftUI

struct FeaturedGameCard: View {
    let game: Game
    let onSelect: () -> Void
    
    @State private var cardScale: CGFloat = 1.0
    @State private var showingDetails = false
    @State private var pulseAnimation = false
    @State private var gradientRotation: Double = 0
    
    // Animated gradient for the featured badge
    private var featuredGradient: LinearGradient {
        LinearGradient(
            colors: [
                .primary.opacity(0.9),
                .primary.opacity(0.7),
                .primary.opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Background gradient using team colors
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                game.homeTeamColors.primary.opacity(0.9),
                game.homeTeamColors.secondary.opacity(0.7),
                game.awayTeamColors.secondary.opacity(0.7),
                game.awayTeamColors.primary.opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        Button(action: {
            hapticFeedback()
            onSelect()
        }) {
            VStack(spacing: 20) {
                // Featured Badge and Time
                HStack {
                    // Featured Badge
                    Label {
                        Text("Featured Game")
                            .font(.system(size: 14, weight: .semibold))
                    } icon: {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        featuredGradient
                            .rotationEffect(.degrees(gradientRotation))
                            .animation(
                                .linear(duration: 3.0)
                                .repeatForever(autoreverses: false),
                                value: gradientRotation
                            )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .primary.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                    
                    // Game Time
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text(game.formattedTime)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
                }
                
                // Teams
                HStack(spacing: 30) {
                    // Away Team
                    FeaturedTeamColumn(
                        name: game.awayTeam,
                        spread: -game.spread,
                        teamColors: game.awayTeamColors,
                        isHome: false
                    )
                    
                    // VS Badge
                    VStack(spacing: 4) {
                        Text("VS")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            
                        // Total Bets Indicator
                        Text("\(game.totalBets) Bets")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    // Home Team
                    FeaturedTeamColumn(
                        name: game.homeTeam,
                        spread: game.spread,
                        teamColors: game.homeTeamColors,
                        isHome: true
                    )
                }
                .padding(.vertical, 10)
            }
            .padding(20)
            .background(
                ZStack {
                    // Base gradient background
                    backgroundGradient
                    
                    // Animated overlay for subtle movement
                    Color.white.opacity(0.1)
                        .mask(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(gradientRotation))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.5),
                                .white.opacity(0.2),
                                .white.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: .backgroundPrimary.opacity(0.3),
                radius: 15,
                x: 0,
                y: 8
            )
            .scaleEffect(cardScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: cardScale)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Start animations
            withAnimation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
            ) {
                pulseAnimation = true
            }
            
            // Rotate gradient
            withAnimation(
                .linear(duration: 10.0)
                .repeatForever(autoreverses: false)
            ) {
                gradientRotation = 360
            }
        }
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                           pressing: { pressing in
            cardScale = pressing ? 0.95 : 1.0
        }, perform: {})
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

struct FeaturedTeamColumn: View {
    let name: String
    let spread: Double
    let teamColors: TeamColors
    let isHome: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Team Name
            Text(name)
                .font(.system(size: 18, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            
            // Spread
            if spread != 0 {
                Text(spread > 0 ? "+\(String(format: "%.1f", spread))" : "\(String(format: "%.1f", spread))")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
            }
            
            // Home/Away Badge
            Text(isHome ? "HOME" : "AWAY")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(teamColors.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.95))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        // Background gradient for preview
        LinearGradient(
            colors: [
                .backgroundPrimary,
                .primary.opacity(0.1),
                .backgroundPrimary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 20) {
            FeaturedGameCard(
                game: Game.sampleGames[0]
            ) {
                print("Featured game selected")
            }
            
            // Add a second card to show multiple states
            FeaturedGameCard(
                game: Game.sampleGames[1]
            ) {
                print("Featured game selected")
            }
        }
        .padding()
    }
}
