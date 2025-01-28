//
//  TeamColors.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/28/25.
//


import SwiftUI

struct TeamColors: Codable {
    let primary: Color
    let secondary: Color
    
    // MARK: - Static Properties
    static let nbaTeamColors: [String: TeamColors] = [
        "Lakers": TeamColors(primary: Color(hex: "552583"), secondary: Color(hex: "FDB927")),
        "Celtics": TeamColors(primary: Color(hex: "007A33"), secondary: Color(hex: "BA9653")),
        "Warriors": TeamColors(primary: Color(hex: "1D428A"), secondary: Color(hex: "FFC72C")),
        "Nets": TeamColors(primary: Color(hex: "000000"), secondary: Color(hex: "FFFFFF")),
        "Knicks": TeamColors(primary: Color(hex: "006BB6"), secondary: Color(hex: "F58426")),
        "Bulls": TeamColors(primary: Color(hex: "CE1141"), secondary: Color(hex: "000000")),
        "Heat": TeamColors(primary: Color(hex: "98002E"), secondary: Color(hex: "F9A01B")),
        "Cavaliers": TeamColors(primary: Color(hex: "860038"), secondary: Color(hex: "041E42")),
        "Suns": TeamColors(primary: Color(hex: "1D1160"), secondary: Color(hex: "E56020")),
        "Bucks": TeamColors(primary: Color(hex: "00471B"), secondary: Color(hex: "EEE1C6")),
        "76ers": TeamColors(primary: Color(hex: "006BB6"), secondary: Color(hex: "ED174C")),
        "Mavericks": TeamColors(primary: Color(hex: "00538C"), secondary: Color(hex: "002B5E")),
        "Hawks": TeamColors(primary: Color(hex: "E03A3E"), secondary: Color(hex: "C1D32F")),
        "Grizzlies": TeamColors(primary: Color(hex: "5D76A9"), secondary: Color(hex: "12173F")),
        "Kings": TeamColors(primary: Color(hex: "5A2D81"), secondary: Color(hex: "63727A")),
        "Rockets": TeamColors(primary: Color(hex: "CE1141"), secondary: Color(hex: "000000")),
        "Hornets": TeamColors(primary: Color(hex: "1D1160"), secondary: Color(hex: "00788C")),
        "Pistons": TeamColors(primary: Color(hex: "C8102E"), secondary: Color(hex: "1D42BA")),
        "Trail Blazers": TeamColors(primary: Color(hex: "E03A3E"), secondary: Color(hex: "000000")),
        "Magic": TeamColors(primary: Color(hex: "0077C0"), secondary: Color(hex: "000000")),
        "Raptors": TeamColors(primary: Color(hex: "CE1141"), secondary: Color(hex: "000000")),
        "Thunder": TeamColors(primary: Color(hex: "007AC1"), secondary: Color(hex: "EF3B24"))
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
        
        self.primary = Color(hex: primaryHex)
        self.secondary = Color(hex: secondaryHex)
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