import SwiftUI

struct FeaturedGameCard: View {
    // MARK: - Properties
    let game: Game
    let onSelect: () -> Void
    
    @State private var cardScale: CGFloat = 1.0
    @State private var showingDetails = false
    @State private var pulseAnimation = false
    @State private var gradientRotation: Double = 0
    
    // MARK: - Computed Properties
    
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
    
    // Enhanced background gradient using team colors
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                game.awayTeamColors.primary.opacity(0.95),
                game.awayTeamColors.secondary.opacity(0.8),
                game.homeTeamColors.secondary.opacity(0.8),
                game.homeTeamColors.primary.opacity(0.95)
            ].map { $0.saturated(by: 1.2) }), // Increase color vibrancy
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            hapticFeedback()
            onSelect()
        }) {
            VStack(spacing: 20) {
                // Featured Badge and Time
                HStack {
                    // Enhanced Featured Badge
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
                        ZStack {
                            // Base gradient
                            featuredGradient
                                .rotationEffect(.degrees(gradientRotation))
                            
                            // Shimmering overlay
                            LinearGradient(
                                colors: [
                                    .white.opacity(0),
                                    .white.opacity(0.3),
                                    .white.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .offset(x: -100)
                            .mask(Capsule())
                            .offset(x: pulseAnimation ? 200 : -200)
                            .animation(
                                .linear(duration: 2.0)
                                .repeatForever(autoreverses: false),
                                value: pulseAnimation
                            )
                        }
                    )
                    .clipShape(Capsule())
                    .shadow(color: .primary.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                    
                    // Game Time with Lock Warning
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text(game.formattedTime)
                            .font(.system(size: 14, weight: .medium))
                        
                        if game.isApproachingLock {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                        }
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
                    // Enhanced gradient background
                    backgroundGradient
                        .opacity(0.95)
                    
                    // Dynamic light rays effect
                    ForEach(0..<3) { index in
                        LinearGradient(
                            colors: [
                                .white.opacity(0),
                                .white.opacity(0.1),
                                .white.opacity(0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .rotationEffect(.degrees(Double(index) * 45 + gradientRotation))
                        .scaleEffect(1.5)
                    }
                    
                    // Animated shimmer effect
                    Color.white.opacity(0.1)
                        .mask(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(gradientRotation))
                        .blendMode(.overlay)
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
            // Add lock warning if needed
            .lockWarning(for: game)
            // Add lock overlay if game is locked
            .overlay(game.shouldBeLocked ? lockOverlay : nil)
            .opacity(game.shouldBeLocked ? 0.7 : 1.0)
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
    
    // MARK: - Helper Views
    
    private var lockOverlay: some View {
        Rectangle()
            .fill(Color.black.opacity(0.5))
            .overlay(
                VStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    Text("Game Locked")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Helper Methods
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Helper Extension for Color Saturation
private extension Color {
    func saturated(by factor: Double) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return Color(UIColor(hue: hue,
                           saturation: min(saturation * CGFloat(factor), 1.0),
                           brightness: brightness,
                           alpha: alpha))
    }
}

// MARK: - Featured Team Column
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
