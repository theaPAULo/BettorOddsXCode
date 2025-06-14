//
//  Color+AppTheme.swift
//  BettorOdds
//
//  Version: 2.2.0 - Complete color definitions for all UI components
//  Updated: June 2025
//

import SwiftUI

extension Color {
    // MARK: - Primary Brand Colors
    static var textPrimary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        })
    }
    
    static var textSecondary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(hex: "A0A0A0") : UIColor(hex: "666666")
        })
    }
    
    static var backgroundPrimary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(hex: "1A1A1A") : .white
        })
    }
    
    static var backgroundSecondary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(hex: "2A2A2A") : UIColor(hex: "F5F5F5")
        })
    }
    
    // FIXED: Primary teal color - your signature color
    static var primary: Color {
        Color(hex: "00E6CA") // Bright teal
    }
    
    static var secondary: Color {
        Color(hex: "4B56D2") // Blue
    }
    
    // MARK: - Status Colors
    static var statusSuccess: Color {
        Color(hex: "4CAF50") // Green
    }
    
    static var statusWarning: Color {
        Color(hex: "FFC107") // Orange/Yellow
    }
    
    static var statusError: Color {
        Color(hex: "FF5252") // Red
    }
    
    // MARK: - Additional UI Colors
    static var cardBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(hex: "2A2A2A") : UIColor(hex: "F8F9FA")
        })
    }
    
    static var borderColor: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(hex: "404040") : UIColor(hex: "E0E0E0")
        })
    }
    
    // MARK: - Asset-based Colors (if you want to use assets)
    static var appPrimary: Color {
        Color("AppPrimary") // Uses asset if available, fallback to primary
    }
    
    static var appSecondary: Color {
        Color("AppSecondary") // Uses asset if available, fallback to secondary
    }
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init(hex: String) {
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
