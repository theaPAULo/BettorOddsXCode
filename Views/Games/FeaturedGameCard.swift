// FeaturedGameCard.swift
// Version: 2.1.0
// Updated with local hex support (preserves readability)

import SwiftUI

struct FeaturedGameCard: View {
    let game: Game
    let onSelect: () -> Void
    
    @State private var isGlowing = false // For animation
    
    // MARK: - Local Hex Helper (avoids conflicts with other extensions)
    private static func colorFromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    var body: some View {
        GameCard(
            game: game,
            isFeatured: true,
            onSelect: onSelect,
            globalSelectedTeam: .constant(nil)
        )
        .overlay(
            // Featured badge with star
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 2, x: 0, y: 0)
                
                Text("Featured")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [
                        Self.colorFromHex("00E6CA").opacity(0.9), // Your app's primary color
                        Self.colorFromHex("00E6CA").opacity(0.7)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
            .padding(12),
            alignment: .topLeading
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Self.colorFromHex("00E6CA").opacity(isGlowing ? 0.7 : 0.3),
                            Self.colorFromHex("00E6CA").opacity(isGlowing ? 0.4 : 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(
            color: Self.colorFromHex("00E6CA").opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
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
