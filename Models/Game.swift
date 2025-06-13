//
//  Game.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 2.1.1 - Added sampleGames extension for previews
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
    
    var score: GameScore?

    // Add computed property for status
    var status: GameStatus {
        if let _ = score { // We'll need to add a way to access the score
            return .completed
        }
        if isLocked {
            return .locked
        }
        if time <= Date() {
            return .inProgress
        }
        return .upcoming
    }
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id, homeTeam, awayTeam, time, league, spread, totalBets
        case homeTeamColors, awayTeamColors, isFeatured, isVisible, isLocked
        case lastUpdatedBy, lastUpdatedAt
        case manuallyFeatured
        case score  // Add this
    }
    
    // MARK: - Computed Properties
    var sortPriority: Int {
        if isFinished { return 2 }  // Put finished games last
        if isLocked { return 1 }    // Put locked games second
        return 0                    // Put active games first
    }
    
    var isFinished: Bool {
        // A game is finished if it has a score and the time has passed
        if let _ = score, time <= Date() {
            return true
        }
        return false
    }
    
    // Add a property to track completion status
    var isCompleted: Bool {
        return score != nil
    }
    
    var homeSpread: String {
        let value = spread
        return value >= 0 ? "+\(String(format: "%.1f", value))" : String(format: "%.1f", value)
    }
    
    var awaySpread: String {
        let value = -spread
        return value >= 0 ? "+\(String(format: "%.1f", value))" : String(format: "%.1f", value)
    }
    
    var shouldBeLocked: Bool {
        // Lock games 15 minutes before start time
        let lockTime = time.addingTimeInterval(-15 * 60) // 15 minutes before
        return Date() >= lockTime
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
         lastUpdatedAt: Date? = nil,
         score: GameScore? = nil) {
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
        self.score = score
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
        score = try container.decodeIfPresent(GameScore.self, forKey: .score)
        
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
        
        // Parse score if it exists in the document
        if let scoreData = data["score"] as? [String: Any] {
            self.score = GameScore(
                gameId: document.documentID,
                homeScore: scoreData["homeScore"] as? Int ?? 0,
                awayScore: scoreData["awayScore"] as? Int ?? 0,
                finalizedAt: (scoreData["finalizedAt"] as? Timestamp)?.dateValue() ?? Date(),
                verifiedAt: (scoreData["verifiedAt"] as? Timestamp)?.dateValue()
            )
            print("📊 Parsed score from document data")
        } else {
            self.score = nil
        }
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
        
        // Add score if available
        if let score = score {
            dict["score"] = score.toDictionary()
        }
        
        if let lastUpdatedBy = lastUpdatedBy {
            dict["lastUpdatedBy"] = lastUpdatedBy
        }
        
        if let lastUpdatedAt = lastUpdatedAt {
            dict["lastUpdatedAt"] = Timestamp(date: lastUpdatedAt)
        }
        
        return dict
    }
}

// MARK: - Game Status Enum
enum GameStatus: String, Codable, CaseIterable {
    case upcoming = "Upcoming"
    case inProgress = "In Progress"
    case locked = "Locked"
    case completed = "Completed"
    
    var color: Color {
        switch self {
        case .upcoming:
            return .blue
        case .inProgress:
            return .orange
        case .locked:
            return .red
        case .completed:
            return .green
        }
    }
}

// MARK: - Sample Data Extension
// This extension provides sample games for previews and testing
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
        ),
        Game(
            id: "3",
            homeTeam: "Miami Heat",
            awayTeam: "Boston Celtics",
            time: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
            league: "NBA",
            spread: -2.5,  // Heat favored by 2.5
            totalBets: 3500,
            homeTeamColors: TeamColors.getTeamColors("Heat"),
            awayTeamColors: TeamColors.getTeamColors("Celtics"),
            isFeatured: true
        ),
        Game(
            id: "4",
            homeTeam: "Los Angeles Lakers",
            awayTeam: "Golden State Warriors",
            time: Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date(),
            league: "NBA",
            spread: 3.0,  // Lakers favored by 3
            totalBets: 5000,
            homeTeamColors: TeamColors.getTeamColors("Lakers"),
            awayTeamColors: TeamColors.getTeamColors("Warriors")
        )
    ]
}
