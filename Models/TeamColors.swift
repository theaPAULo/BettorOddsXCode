//
//  TeamColors.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/28/25.
//  Version: 2.0.0 - Added local hex support for readability
//

import SwiftUI

struct TeamColors: Codable {
    let primary: Color
    let secondary: Color
    
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
    
    // MARK: - Static Properties
    static let nbaTeamColors: [String: TeamColors] = [
        "Lakers": TeamColors(primary: colorFromHex("552583"), secondary: colorFromHex("FDB927")),
        "Celtics": TeamColors(primary: colorFromHex("007A33"), secondary: colorFromHex("BA9653")),
        "Warriors": TeamColors(primary: colorFromHex("1D428A"), secondary: colorFromHex("FFC72C")),
        "Nets": TeamColors(primary: colorFromHex("000000"), secondary: colorFromHex("FFFFFF")),
        "Knicks": TeamColors(primary: colorFromHex("006BB6"), secondary: colorFromHex("F58426")),
        "Bulls": TeamColors(primary: colorFromHex("CE1141"), secondary: colorFromHex("000000")),
        "Heat": TeamColors(primary: colorFromHex("98002E"), secondary: colorFromHex("F9A01B")),
        "Cavaliers": TeamColors(primary: colorFromHex("860038"), secondary: colorFromHex("041E42")),
        "Suns": TeamColors(primary: colorFromHex("1D1160"), secondary: colorFromHex("E56020")),
        "Bucks": TeamColors(primary: colorFromHex("00471B"), secondary: colorFromHex("EEE1C6")),
        "76ers": TeamColors(primary: colorFromHex("006BB6"), secondary: colorFromHex("ED174C")),
        "Mavericks": TeamColors(primary: colorFromHex("00538C"), secondary: colorFromHex("002B5E")),
        "Hawks": TeamColors(primary: colorFromHex("E03A3E"), secondary: colorFromHex("C1D32F")),
        "Grizzlies": TeamColors(primary: colorFromHex("5D76A9"), secondary: colorFromHex("12173F")),
        "Kings": TeamColors(primary: colorFromHex("5A2D81"), secondary: colorFromHex("63727A")),
        "Rockets": TeamColors(primary: colorFromHex("CE1141"), secondary: colorFromHex("000000")),
        "Hornets": TeamColors(primary: colorFromHex("1D1160"), secondary: colorFromHex("00788C")),
        "Pistons": TeamColors(primary: colorFromHex("C8102E"), secondary: colorFromHex("1D42BA")),
        "Trail Blazers": TeamColors(primary: colorFromHex("E03A3E"), secondary: colorFromHex("000000")),
        "Magic": TeamColors(primary: colorFromHex("0077C0"), secondary: colorFromHex("000000")),
        "Raptors": TeamColors(primary: colorFromHex("CE1141"), secondary: colorFromHex("000000")),
        "Nuggets": TeamColors(primary: colorFromHex("0E2240"), secondary: colorFromHex("FEC524")),
        "Pacers": TeamColors(primary: colorFromHex("002D62"), secondary: colorFromHex("FDBB30")),
        "Clippers": TeamColors(primary: colorFromHex("C8102E"), secondary: colorFromHex("1D428A")),
        "Timberwolves": TeamColors(primary: colorFromHex("0C2340"), secondary: colorFromHex("236192")),
        "Pelicans": TeamColors(primary: colorFromHex("0C2340"), secondary: colorFromHex("C8102E")),
        "Thunder": TeamColors(primary: colorFromHex("007AC1"), secondary: colorFromHex("EF3B24")),
        "Spurs": TeamColors(primary: colorFromHex("C4CED4"), secondary: colorFromHex("000000")),
        "Jazz": TeamColors(primary: colorFromHex("002B5C"), secondary: colorFromHex("E31837")),
        "Wizards": TeamColors(primary: colorFromHex("002B5C"), secondary: colorFromHex("E31837"))
    ]
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case primaryHex, secondaryHex
    }
    
    // MARK: - Initialization
    init(primary: Color, secondary: Color) {
        self.primary = primary
        self.secondary = secondary
    }
    
    // MARK: - Codable Implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let primaryHex = try container.decode(String.self, forKey: .primaryHex)
        let secondaryHex = try container.decode(String.self, forKey: .secondaryHex)
        
        self.primary = TeamColors.colorFromHex(primaryHex)
        self.secondary = TeamColors.colorFromHex(secondaryHex)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Note: Since we can't directly get hex from Color, this is a placeholder
        try container.encode("#000000", forKey: .primaryHex)
        try container.encode("#000000", forKey: .secondaryHex)
    }
    
    // MARK: - Helper Methods
    static func getTeamColors(_ teamName: String) -> TeamColors {
        // Look for exact match first
        if let colors = nbaTeamColors[teamName] {
            return colors
        }
        
        // Look for partial matches
        for (key, colors) in nbaTeamColors {
            if teamName.contains(key) {
                return colors
            }
        }
        
        // Default colors if team not found
        return TeamColors(primary: .gray, secondary: .black)
    }
}
