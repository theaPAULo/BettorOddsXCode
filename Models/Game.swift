//
//  Game.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 2.1.0
//

import SwiftUI
import FirebaseFirestore

struct Game: Identifiable, Codable {
    // MARK: - Properties
    let id: String
    let homeTeam: String
    let awayTeam: String
    let time: Date
    let league: String
    let spread: Double
    let totalBets: Int
    let homeTeamColors: TeamColors
    let awayTeamColors: TeamColors
    var isFeatured: Bool
    var manuallyFeatured: Bool = false
    var isVisible: Bool
    var isLocked: Bool
    var lastUpdatedBy: String?
    var lastUpdatedAt: Date?
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id, homeTeam, awayTeam, time, league, spread, totalBets
        case homeTeamColors, awayTeamColors, isFeatured, isVisible, isLocked
        case lastUpdatedBy, lastUpdatedAt
        case manuallyFeatured
    }
    
    // MARK: - Computed Properties
    var sortPriority: Int {
        if isFinished { return 2 }  // Put finished games last
        if isLocked { return 1 }    // Put locked games second
        return 0                    // Put active games first
    }
    
    var isFinished: Bool {
        // This will be determined by presence in The Odds API
        // Default to false - the sync process will handle cleanup
        return false
    }
    
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
    
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • h:mm a" // Shows like "Feb 2 • 7:40 PM"
        return formatter.string(from: time)
    }
    
    // MARK: - Lock Timing Properties
    static let lockBeforeGameMinutes: Double = 5
    static let warningBeforeLockMinutes: Double = 1
    static let visualIndicatorStartMinutes: Double = 15

    var timeUntilGame: TimeInterval {
        return time.timeIntervalSinceNow
    }

    var timeUntilLock: TimeInterval {
        return timeUntilGame - (Self.lockBeforeGameMinutes * 60)
    }

    var shouldBeLocked: Bool {
        // Lock if:
        // 1. Within 5 minutes of start time OR
        // 2. Game has started
        return timeUntilLock <= 0 || time <= Date()
    }

    var isApproachingLock: Bool {
        let warningTime = Self.warningBeforeLockMinutes * 60
        return timeUntilLock > 0 && timeUntilLock <= warningTime
    }

    var needsVisualIndicator: Bool {
        let indicatorTime = Self.visualIndicatorStartMinutes * 60
        return timeUntilLock > 0 && timeUntilLock <= indicatorTime
    }

    var visualIntensity: Double {
        guard needsVisualIndicator else { return 0.0 }
        
        let indicatorTime = Self.visualIndicatorStartMinutes * 60
        let intensity = 1.0 - (timeUntilLock / indicatorTime)
        return min(max(intensity, 0.0), 1.0)
    }

    var formattedTimeUntilLock: String {
        guard timeUntilLock > 0 else { return "Locked" }
        
        let minutes = Int(timeUntilLock / 60)
        let seconds = Int(timeUntilLock.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    var lockWarningMessage: String? {
        if isApproachingLock {
            return "Game locking in \(formattedTimeUntilLock)"
        }
        return nil
    }
    
    // MARK: - Initialization
    init(id: String,
         homeTeam: String,
         awayTeam: String,
         time: Date,
         league: String,
         spread: Double,
         totalBets: Int,
         homeTeamColors: TeamColors,
         awayTeamColors: TeamColors,
         isFeatured: Bool = false,
         manuallyFeatured: Bool = false,
         isVisible: Bool = true,
         isLocked: Bool = false,
         lastUpdatedBy: String? = nil,
         lastUpdatedAt: Date? = nil) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.time = time
        self.league = league
        self.spread = spread
        self.totalBets = totalBets
        self.homeTeamColors = homeTeamColors
        self.awayTeamColors = awayTeamColors
        self.isFeatured = isFeatured
        self.manuallyFeatured = manuallyFeatured
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.lastUpdatedBy = lastUpdatedBy
        self.lastUpdatedAt = lastUpdatedAt
    }
    
    // MARK: - Codable Implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        homeTeam = try container.decode(String.self, forKey: .homeTeam)
        awayTeam = try container.decode(String.self, forKey: .awayTeam)
        time = try container.decode(Date.self, forKey: .time)
        league = try container.decode(String.self, forKey: .league)
        spread = try container.decode(Double.self, forKey: .spread)
        totalBets = try container.decode(Int.self, forKey: .totalBets)
        isFeatured = try container.decode(Bool.self, forKey: .isFeatured)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        isLocked = try container.decode(Bool.self, forKey: .isLocked)
        lastUpdatedBy = try container.decodeIfPresent(String.self, forKey: .lastUpdatedBy)
        lastUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .lastUpdatedAt)
        manuallyFeatured = try container.decodeIfPresent(Bool.self, forKey: .manuallyFeatured) ?? false
        
        homeTeamColors = TeamColors.getTeamColors(homeTeam)
        awayTeamColors = TeamColors.getTeamColors(awayTeam)
    }
    
    // MARK: - Firestore Initialization
    init?(from document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        print("🎲 Parsing game document: \(document.documentID)")
        
        self.id = document.documentID
        self.homeTeam = data["homeTeam"] as? String ?? ""
        self.awayTeam = data["awayTeam"] as? String ?? ""
        self.time = (data["time"] as? Timestamp)?.dateValue() ?? Date()
        self.league = data["league"] as? String ?? ""
        self.spread = data["spread"] as? Double ?? 0.0
        self.totalBets = data["totalBets"] as? Int ?? 0
        
        self.isFeatured = data["isFeatured"] as? Bool ?? false
        self.manuallyFeatured = data["manuallyFeatured"] as? Bool ?? false
        self.isVisible = data["isVisible"] as? Bool ?? true
        self.isLocked = data["isLocked"] as? Bool ?? false
        
        print("""
            📊 Game \(document.documentID) properties:
            - isFeatured: \(self.isFeatured)
            - manuallyFeatured: \(self.manuallyFeatured)
            - isVisible: \(self.isVisible)
            - isLocked: \(self.isLocked)
            """)
        
        self.lastUpdatedBy = data["lastUpdatedBy"] as? String
        self.lastUpdatedAt = (data["lastUpdatedAt"] as? Timestamp)?.dateValue()
        
        self.homeTeamColors = TeamColors.getTeamColors(self.homeTeam)
        self.awayTeamColors = TeamColors.getTeamColors(self.awayTeam)
    }
    
    // MARK: - Dictionary Conversion
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "homeTeam": homeTeam,
            "awayTeam": awayTeam,
            "time": Timestamp(date: time),
            "league": league,
            "spread": spread,
            "totalBets": totalBets,
            "isFeatured": isFeatured,
            "manuallyFeatured": manuallyFeatured,
            "isVisible": isVisible,
            "isLocked": isLocked
        ]
        
        if let lastUpdatedBy = lastUpdatedBy {
            dict["lastUpdatedBy"] = lastUpdatedBy
        }
        
        if let lastUpdatedAt = lastUpdatedAt {
            dict["lastUpdatedAt"] = Timestamp(date: lastUpdatedAt)
        }
        
        return dict
    }
    
    // MARK: - Debug
    func debugDescription() -> String {
        return """
        Game ID: \(id)
        Home Team: \(homeTeam)
        Away Team: \(awayTeam)
        Time: \(time)
        League: \(league)
        Spread: \(spread)
        Is Featured: \(isFeatured)
        Is Locked: \(isLocked)
        """
    }
}

// MARK: - Game Sorting
extension Array where Element == Game {
    func sortedByPriority() -> [Game] {
        self.sorted { game1, game2 in
            if game1.sortPriority != game2.sortPriority {
                return game1.sortPriority < game2.sortPriority
            }
            return game1.time < game2.time
        }
    }
}
