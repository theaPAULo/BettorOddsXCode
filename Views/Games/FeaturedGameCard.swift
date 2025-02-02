// FeaturedGameCard.swift
// Version: 2.0.0
// Updated design for featured game cards

import SwiftUI

struct FeaturedGameCard: View {
    // MARK: - Properties
    let game: Game
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        GameCard(
            game: game,
            isFeatured: true,
            onSelect: onSelect,
            globalSelectedTeam: .constant(nil)
        )
        .overlay(
            // Featured badge
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    Text("Featured")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [
                            game.homeTeamColors.primary.opacity(0.9),
                            game.homeTeamColors.secondary.opacity(0.9)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(8),
            alignment: .topLeading
        )
        // Add a subtle border glow
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            game.homeTeamColors.primary.opacity(0.5),
                            game.homeTeamColors.secondary.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        // Add subtle hover effect
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    FeaturedGameCard(
        game: Game.sampleGames[0],
        onSelect: {}
    )
    .padding()
}
