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
    let spread: Double  // Positive for underdog, negative for favorite
    let totalBets: Int  // For determining featured game
    
    // Team colors
    let homeTeamColors: TeamColors
    let awayTeamColors: TeamColors
    
    var isLive: Bool {
        let now = Date()
        return now >= time && now <= time.addingTimeInterval(3 * 60 * 60) // 3 hours for game duration
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
        "Trail Blazers": TeamColors(primary: Color(hex: "E03A3E"), secondary: Color(hex: "000000")),
        "Magic": TeamColors(primary: Color(hex: "0077C0"), secondary: Color(hex: "000000")),
        "Raptors": TeamColors(primary: Color(hex: "CE1141"), secondary: Color(hex: "000000")),
        "Hawks": TeamColors(primary: Color(hex: "E03A3E"), secondary: Color(hex: "C1D32F")),
        "Mavericks": TeamColors(primary: Color(hex: "00538C"), secondary: Color(hex: "002B5E")),
        "Thunder": TeamColors(primary: Color(hex: "007AC1"), secondary: Color(hex: "EF3B24"))
        // Add more teams as needed
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
