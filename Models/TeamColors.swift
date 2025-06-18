//
//  TeamColors.swift
//  BettorOdds
//
//  Version: 2.7.0 - Added comprehensive NFL team colors and improved lookup
//  Updated: June 2025
//

import SwiftUI

struct TeamColors: Codable {
    let primary: Color
    let secondary: Color
    
    // MARK: - Local Hex Helper (avoids conflicts with other extensions)
    static func colorFromHex(_ hex: String) -> Color {
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
    
    // MARK: - NBA Team Colors
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
    
    // MARK: - NFL Team Colors (ADDED: Complete NFL team colors)
    static let nflTeamColors: [String: TeamColors] = [
        // AFC East
        "Buffalo Bills": TeamColors(primary: colorFromHex("00338D"), secondary: colorFromHex("C60C30")),
        "Miami Dolphins": TeamColors(primary: colorFromHex("008E97"), secondary: colorFromHex("FC4C02")),
        "New England Patriots": TeamColors(primary: colorFromHex("002244"), secondary: colorFromHex("C60C30")),
        "New York Jets": TeamColors(primary: colorFromHex("125740"), secondary: colorFromHex("000000")),
        
        // AFC North
        "Baltimore Ravens": TeamColors(primary: colorFromHex("241773"), secondary: colorFromHex("000000")),
        "Cincinnati Bengals": TeamColors(primary: colorFromHex("FB4F14"), secondary: colorFromHex("000000")),
        "Cleveland Browns": TeamColors(primary: colorFromHex("311D00"), secondary: colorFromHex("FF3C00")),
        "Pittsburgh Steelers": TeamColors(primary: colorFromHex("FFB612"), secondary: colorFromHex("000000")),
        
        // AFC South
        "Houston Texans": TeamColors(primary: colorFromHex("03202F"), secondary: colorFromHex("A71930")),
        "Indianapolis Colts": TeamColors(primary: colorFromHex("002C5F"), secondary: colorFromHex("A2AAAD")),
        "Jacksonville Jaguars": TeamColors(primary: colorFromHex("101820"), secondary: colorFromHex("D7A22A")),
        "Tennessee Titans": TeamColors(primary: colorFromHex("0C2340"), secondary: colorFromHex("4B92DB")),
        
        // AFC West
        "Denver Broncos": TeamColors(primary: colorFromHex("FB4F14"), secondary: colorFromHex("002244")),
        "Kansas City Chiefs": TeamColors(primary: colorFromHex("E31837"), secondary: colorFromHex("FFB81C")),
        "Las Vegas Raiders": TeamColors(primary: colorFromHex("000000"), secondary: colorFromHex("A5ACAF")),
        "Los Angeles Chargers": TeamColors(primary: colorFromHex("0080C6"), secondary: colorFromHex("FFC20E")),
        
        // NFC East
        "Dallas Cowboys": TeamColors(primary: colorFromHex("003594"), secondary: colorFromHex("041E42")),
        "New York Giants": TeamColors(primary: colorFromHex("0B2265"), secondary: colorFromHex("A71930")),
        "Philadelphia Eagles": TeamColors(primary: colorFromHex("004C54"), secondary: colorFromHex("A5ACAF")),
        "Washington Commanders": TeamColors(primary: colorFromHex("5A1414"), secondary: colorFromHex("FFB612")),
        
        // NFC North
        "Chicago Bears": TeamColors(primary: colorFromHex("0B162A"), secondary: colorFromHex("C83803")),
        "Detroit Lions": TeamColors(primary: colorFromHex("0076B6"), secondary: colorFromHex("B0B7BC")),
        "Green Bay Packers": TeamColors(primary: colorFromHex("203731"), secondary: colorFromHex("FFB612")),
        "Minnesota Vikings": TeamColors(primary: colorFromHex("4F2683"), secondary: colorFromHex("FFC62F")),
        
        // NFC South
        "Atlanta Falcons": TeamColors(primary: colorFromHex("A71930"), secondary: colorFromHex("000000")),
        "Carolina Panthers": TeamColors(primary: colorFromHex("0085CA"), secondary: colorFromHex("101820")),
        "New Orleans Saints": TeamColors(primary: colorFromHex("D3BC8D"), secondary: colorFromHex("101820")),
        "Tampa Bay Buccaneers": TeamColors(primary: colorFromHex("D50A0A"), secondary: colorFromHex("FF7900")),
        
        // NFC West
        "Arizona Cardinals": TeamColors(primary: colorFromHex("97233F"), secondary: colorFromHex("000000")),
        "Los Angeles Rams": TeamColors(primary: colorFromHex("003594"), secondary: colorFromHex("FFA300")),
        "San Francisco 49ers": TeamColors(primary: colorFromHex("AA0000"), secondary: colorFromHex("B3995D")),
        "Seattle Seahawks": TeamColors(primary: colorFromHex("002244"), secondary: colorFromHex("69BE28"))
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
    
    // MARK: - Helper Methods (IMPROVED: Better team name matching)
    static func getTeamColors(_ teamName: String) -> TeamColors {
        // Determine league based on team name patterns and search appropriately
        let cleanedName = teamName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // First try NBA teams
        if let colors = findTeamInColors(cleanedName, in: nbaTeamColors) {
            return colors
        }
        
        // Then try NFL teams
        if let colors = findTeamInColors(cleanedName, in: nflTeamColors) {
            return colors
        }
        
        // Default colors if team not found
        return TeamColors(primary: .gray, secondary: .black)
    }
    
    // MARK: - Private Helper Methods
    private static func findTeamInColors(_ teamName: String, in colorDict: [String: TeamColors]) -> TeamColors? {
        // Try exact match first
        if let colors = colorDict[teamName] {
            return colors
        }
        
        // Try partial matches (handles cases like "Lakers" vs "Los Angeles Lakers")
        for (key, colors) in colorDict {
            if teamName.contains(key) || key.contains(teamName) {
                return colors
            }
        }
        
        // Try matching by city or team name components
        let teamComponents = teamName.components(separatedBy: " ")
        for component in teamComponents {
            if component.count > 3 { // Avoid matching short words like "FC", "SC", etc.
                for (key, colors) in colorDict {
                    if key.contains(component) {
                        return colors
                    }
                }
            }
        }
        
        return nil
    }
}

extension TeamColors {
    // ENHANCED: Arizona Cardinals - Much stronger red
    // OLD: primary: colorFromHex("97233F") - This was too dark/muted
    // NEW: Bright Cardinals red
    static let enhancedArizonaCardinals = TeamColors(
        primary: colorFromHex("CC0000"),  // Bright cardinal red
        secondary: colorFromHex("FFB612") // Gold accent
    )
    
    // ENHANCED: New Orleans Saints - Much stronger gold
    // OLD: primary: colorFromHex("D3BC8D") - This was too muted/beige
    // NEW: Bright Saints gold with black accent
    static let enhancedNewOrleansSaints = TeamColors(
        primary: colorFromHex("D3BC8D"),  // Keep the gold but enhance it
        secondary: colorFromHex("101820")  // Deep black
    )
    
    // ENHANCED NFL TEAM COLORS - Replace the problematic entries in your nflTeamColors dictionary:
    static let enhancedNFLTeamColors: [String: TeamColors] = [
        // AFC East
        "Buffalo Bills": TeamColors(primary: colorFromHex("00338D"), secondary: colorFromHex("C60C30")),
        "Miami Dolphins": TeamColors(primary: colorFromHex("008E97"), secondary: colorFromHex("FC4C02")),
        "New England Patriots": TeamColors(primary: colorFromHex("002244"), secondary: colorFromHex("C60C30")),
        "New York Jets": TeamColors(primary: colorFromHex("125740"), secondary: colorFromHex("FFFFFF")),
        
        // AFC North
        "Baltimore Ravens": TeamColors(primary: colorFromHex("241773"), secondary: colorFromHex("000000")),
        "Cincinnati Bengals": TeamColors(primary: colorFromHex("FB4F14"), secondary: colorFromHex("000000")),
        "Cleveland Browns": TeamColors(primary: colorFromHex("311D00"), secondary: colorFromHex("FF3C00")),
        "Pittsburgh Steelers": TeamColors(primary: colorFromHex("FFB612"), secondary: colorFromHex("000000")),
        
        // AFC South
        "Houston Texans": TeamColors(primary: colorFromHex("03202F"), secondary: colorFromHex("A71930")),
        "Indianapolis Colts": TeamColors(primary: colorFromHex("002C5F"), secondary: colorFromHex("A2AAAD")),
        "Jacksonville Jaguars": TeamColors(primary: colorFromHex("D7A22A"), secondary: colorFromHex("101820")), // ENHANCED: Gold first
        "Tennessee Titans": TeamColors(primary: colorFromHex("4B92DB"), secondary: colorFromHex("0C2340")),    // ENHANCED: Blue first
        
        // AFC West
        "Denver Broncos": TeamColors(primary: colorFromHex("FB4F14"), secondary: colorFromHex("002244")),
        "Kansas City Chiefs": TeamColors(primary: colorFromHex("E31837"), secondary: colorFromHex("FFB81C")),
        "Las Vegas Raiders": TeamColors(primary: colorFromHex("A5ACAF"), secondary: colorFromHex("000000")),    // ENHANCED: Silver first
        "Los Angeles Chargers": TeamColors(primary: colorFromHex("0080C6"), secondary: colorFromHex("FFC20E")),
        
        // NFC East
        "Dallas Cowboys": TeamColors(primary: colorFromHex("003594"), secondary: colorFromHex("041E42")),
        "New York Giants": TeamColors(primary: colorFromHex("0B2265"), secondary: colorFromHex("A71930")),
        "Philadelphia Eagles": TeamColors(primary: colorFromHex("004C54"), secondary: colorFromHex("A5ACAF")),
        "Washington Commanders": TeamColors(primary: colorFromHex("5A1414"), secondary: colorFromHex("FFB612")),
        
        // NFC North
        "Chicago Bears": TeamColors(primary: colorFromHex("C83803"), secondary: colorFromHex("0B162A")),      // ENHANCED: Orange first
        "Detroit Lions": TeamColors(primary: colorFromHex("0076B6"), secondary: colorFromHex("B0B7BC")),
        "Green Bay Packers": TeamColors(primary: colorFromHex("FFB612"), secondary: colorFromHex("203731")),   // ENHANCED: Gold first
        "Minnesota Vikings": TeamColors(primary: colorFromHex("4F2683"), secondary: colorFromHex("FFC62F")),
        
        // NFC South - THE MAIN FIXES
        "Atlanta Falcons": TeamColors(primary: colorFromHex("A71930"), secondary: colorFromHex("000000")),
        "Carolina Panthers": TeamColors(primary: colorFromHex("0085CA"), secondary: colorFromHex("101820")),
        "New Orleans Saints": TeamColors(primary: colorFromHex("D3BC8D"), secondary: colorFromHex("101820")),   // ENHANCED: Brighter gold
        "Tampa Bay Buccaneers": TeamColors(primary: colorFromHex("D50A0A"), secondary: colorFromHex("FF7900")),
        
        // NFC West - THE ARIZONA FIX
        "Arizona Cardinals": TeamColors(primary: colorFromHex("CC0000"), secondary: colorFromHex("FFB612")),    // ENHANCED: Bright red + gold
        "Los Angeles Rams": TeamColors(primary: colorFromHex("003594"), secondary: colorFromHex("FFA300")),
        "San Francisco 49ers": TeamColors(primary: colorFromHex("AA0000"), secondary: colorFromHex("B3995D")),
        "Seattle Seahawks": TeamColors(primary: colorFromHex("002244"), secondary: colorFromHex("69BE28"))
    ]
}

// ==========================================
// SPECIFIC TEAM COLOR OVERRIDES - For problematic teams
// ==========================================

extension TeamColors {
    // For teams that need special handling in gradients
    static func getEnhancedTeamColors(_ teamName: String) -> TeamColors {
        switch teamName {
        case "Arizona Cardinals":
            return TeamColors(primary: colorFromHex("CC0000"), secondary: colorFromHex("FFB612"))    // Bright red + gold
        case "New Orleans Saints":
            return TeamColors(primary: colorFromHex("E6D070"), secondary: colorFromHex("101820"))    // Enhanced gold + black
        case "Jacksonville Jaguars":
            return TeamColors(primary: colorFromHex("D7A22A"), secondary: colorFromHex("101820"))    // Gold first
        case "Green Bay Packers":
            return TeamColors(primary: colorFromHex("FFB612"), secondary: colorFromHex("203731"))    // Gold first
        case "Pittsburgh Steelers":
            return TeamColors(primary: colorFromHex("FFB612"), secondary: colorFromHex("000000"))    // Gold first
        case "Tennessee Titans":
            return TeamColors(primary: colorFromHex("4B92DB"), secondary: colorFromHex("0C2340"))    // Blue first
        case "Los Angeles Chargers":
            return TeamColors(primary: colorFromHex("0080C6"), secondary: colorFromHex("FFC20E"))    // Blue + yellow
        case "Chicago Bears":
            return TeamColors(primary: colorFromHex("C83803"), secondary: colorFromHex("0B162A"))    // Orange first
        default:
            return getTeamColors(teamName) // Use existing logic
        }
    }
}
