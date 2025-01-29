//
//  Color+AppTheme.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/28/25.
//


import SwiftUI

extension Color {
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
    
    static var primary: Color {
        Color(hex: "00E6CA")
    }
    
    static var secondary: Color {
        Color(hex: "4B56D2")
    }
    
    static var statusSuccess: Color {
        Color(hex: "4CAF50")
    }
    
    static var statusWarning: Color {
        Color(hex: "FFC107")
    }
    
    static var statusError: Color {
        Color(hex: "FF5252")
    }
}

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
