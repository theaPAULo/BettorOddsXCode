//
//  AnimatedBackground.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.1.0 - Updated with local hex support (preserves readability)
//

import SwiftUI

struct AnimatedBackground: View {
    // MARK: - Properties
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateGradient = false
    
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
    
    // MARK: - Color Sets
    private var colors: [Color] {
        colorScheme == .dark ? darkModeColors : lightModeColors
    }
    
    // Now we can use readable hex values!
    private let lightModeColors = [
        colorFromHex("f8f9fa").opacity(0.8),
        colorFromHex("e9ecef").opacity(0.8),
        colorFromHex("dee2e6").opacity(0.8)
    ]
    
    private let darkModeColors = [
        colorFromHex("212529").opacity(0.8),
        colorFromHex("343a40").opacity(0.8),
        colorFromHex("495057").opacity(0.8)
    ]
    
    // MARK: - Body
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .linear(duration: 5.0)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient.toggle()
            }
        }
    }
}

#Preview {
    VStack {
        Text("Sample Content")
            .font(.title)
            .foregroundColor(.primary)
    }
    .background(AnimatedBackground())
}
