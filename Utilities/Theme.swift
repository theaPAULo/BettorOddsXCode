//
//  AppTheme.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//


// File: Utilities/Theme.swift
// Version: 1.0
// Description: App-wide color and style definitions

import SwiftUI

struct AppTheme {
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let background = Color("Background")
    static let yellowCoin = Color(hex: "FFD700")
    static let greenCoin = Color(hex: "22C55E")
    
    // Add hex color support
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    
    struct ButtonStyle {
        static let cornerRadius: CGFloat = 12
        static let height: CGFloat = 56
        static let fontSize: CGFloat = 16
    }
}

// Extension to support hex colors
extension Color {
    init(hex: String) {
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
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}