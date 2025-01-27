//
//  Game.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//

import SwiftUI

struct Game: Identifiable {
    let id: String
    let homeTeam: String
    let awayTeam: String
    let time: Date
    let league: String
    let spread: Double  // Positive means home team is underdog, negative means home team is favorite
    let totalBets: Int
    
    // Team colors
    let homeTeamColors: TeamColors
    let awayTeamColors: TeamColors
    
    // Computed properties for spreads
    var homeSpread: String {
        let value = spread
        return value >= 0 ? "+\(String(format: "%.1f", value))" : String(format: "%.1f", value)
    }
    
    var awaySpread: String {
        let value = -spread
        return value >= 0 ? "+\(String(format: "%.1f", value))" : String(format: "%.1f", value)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
}

struct TeamColors {
    let primary: Color
    let secondary: Color
    
    // NBA Team Colors
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
    
    static func getTeamColors(_ teamName: String) -> TeamColors {
        for (key, colors) in nbaTeamColors {
            if teamName.contains(key) {
                return colors
            }
        }
        // Default colors if team not found
        return TeamColors(primary: .gray, secondary: .black)
    }
}

// Sample Data
extension Game {
    static var sampleGames: [Game] = [
        Game(
            id: "1",
            homeTeam: "Orlando Magic",
            awayTeam: "Portland Trail Blazers",
            time: Calendar.current.date(bySettingHour: 18, minute: 10, second: 0, of: Date()) ?? Date(),
            league: "NBA",
            spread: 6.5,  // Magic favored by 6.5
            totalBets: 1500,
            homeTeamColors: TeamColors.getTeamColors("Magic"),
            awayTeamColors: TeamColors.getTeamColors("Trail Blazers")
        ),
        Game(
            id: "2",
            homeTeam: "Atlanta Hawks",
            awayTeam: "Toronto Raptors",
            time: Calendar.current.date(bySettingHour: 18, minute: 40, second: 0, of: Date()) ?? Date(),
            league: "NBA",
            spread: 5.0,  // Hawks favored by 5
            totalBets: 2000,
            homeTeamColors: TeamColors.getTeamColors("Hawks"),
            awayTeamColors: TeamColors.getTeamColors("Raptors")
        )
    ]
}
