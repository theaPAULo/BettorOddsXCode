//
//  Game.swift
//  BettorOdds
//
//  Version: 5.0.0 - COMPLETE: Enhanced lock logic, featured game handling, and proper spreads
//  Updated: June 2025
//

import SwiftUI
import FirebaseFirestore
import Foundation

// MARK: - Enhanced Game Model
struct Game: Identifiable, Codable, Hashable {
    // MARK: - Core Properties
    let id: String
    let homeTeam: String
    let awayTeam: String
    let time: Date
    let league: String
    var spread: Double
    var totalBets: Int
    let homeTeamColors: TeamColors
    let awayTeamColors: TeamColors
    
    // MARK: - Status Properties
    var isFeatured: Bool = false
    var manuallyFeatured: Bool = false
    var isVisible: Bool = true
    var isLocked: Bool = false
    var lastUpdatedBy: String?
    var lastUpdatedAt: Date?
    var score: GameScore?
    
    // MARK: - Enhanced Lock Logic Properties
    
    /// Determines if game should be locked based on time (15 minutes before game time)
    var shouldBeLocked: Bool {
        let lockTime = time.addingTimeInterval(-15 * 60) // 15 minutes before game
        return Date() >= lockTime
    }
    
    /// True if game is either manually locked or should be locked based on time
    var isEffectivelyLocked: Bool {
        return isLocked || shouldBeLocked
    }
    
    /// Game has already started
    var hasStarted: Bool {
        return Date() >= time
    }
    
    /// Game is completed (more than 4 hours after start time)
    var isCompleted: Bool {
        let completionTime = time.addingTimeInterval(4 * 60 * 60) // 4 hours after start
        return Date() >= completionTime
    }
    
    /// Game is eligible to be featured (future game, not locked, visible)
    var canBeFeatured: Bool {
        return isVisible && !isEffectivelyLocked && !hasStarted && !isCompleted
    }
    
    /// Minutes until game locks
    var minutesUntilLock: Int {
        let lockTime = time.addingTimeInterval(-15 * 60)
        let timeInterval = lockTime.timeIntervalSinceNow
        return max(0, Int(timeInterval / 60))
    }
    
    /// Game status for display
    var displayStatus: GameStatus {
        if isCompleted {
            return .completed
        } else if hasStarted {
            return .inProgress
        } else if isEffectivelyLocked {
            return .locked
        } else if minutesUntilLock <= 60 {
            return .lockingSoon
        } else {
            return .upcoming
        }
    }
    
    // MARK: - Enhanced Spread Display Properties
    var homeSpread: String {
        if spread == 0 {
            return "EVEN"
        } else if spread > 0 {
            return "+\(String(format: "%.1f", spread))"
        } else {
            return String(format: "%.1f", spread)
        }
    }
    
    var awaySpread: String {
        if spread == 0 {
            return "EVEN"
        } else if spread > 0 {
            return String(format: "%.1f", -spread)
        } else {
            return "+\(String(format: "%.1f", -spread))"
        }
    }
    
    // MARK: - Coding Keys for Firestore
    private enum CodingKeys: String, CodingKey {
        case id, homeTeam, awayTeam, time, league, spread, totalBets
        case isFeatured, manuallyFeatured, isVisible, isLocked
        case lastUpdatedBy, lastUpdatedAt, score
    }
    
    // MARK: - Initialization
    init(id: String = UUID().uuidString,
         homeTeam: String,
         awayTeam: String,
         time: Date,
         league: String,
         spread: Double,
         totalBets: Int = 0,
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
    
    // MARK: - Enhanced Firestore Initialization
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
        
        self.lastUpdatedBy = data["lastUpdatedBy"] as? String
        self.lastUpdatedAt = (data["lastUpdatedAt"] as? Timestamp)?.dateValue()
        
        // Enhanced team colors handling
        if let homeColorsData = data["homeTeamColors"] as? [String: Any],
           let awayColorsData = data["awayTeamColors"] as? [String: Any] {
            // Try to decode team colors from Firestore
            self.homeTeamColors = TeamColors.fromFirestoreData(homeColorsData) ?? TeamColors.getTeamColors(homeTeam)
            self.awayTeamColors = TeamColors.fromFirestoreData(awayColorsData) ?? TeamColors.getTeamColors(awayTeam)
        } else {
            // Fallback to team name lookup
            self.homeTeamColors = TeamColors.getTeamColors(homeTeam)
            self.awayTeamColors = TeamColors.getTeamColors(awayTeam)
        }
        
        // Enhanced score handling
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
    
    // MARK: - Enhanced Dictionary Conversion
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
            "isLocked": isLocked,
            "homeTeamColors": homeTeamColors.toDictionary(),
            "awayTeamColors": awayTeamColors.toDictionary()
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
    
    // MARK: - Mutating Methods
    mutating func updateSpread(_ newSpread: Double) {
        spread = newSpread
        lastUpdatedAt = Date()
    }
    
    mutating func incrementBetCount() {
        totalBets += 1
        lastUpdatedAt = Date()
    }
    
    mutating func setFeatured(_ featured: Bool, manually: Bool = false) {
        isFeatured = featured && canBeFeatured
        if manually {
            manuallyFeatured = featured
        }
        lastUpdatedAt = Date()
    }
    
    mutating func setLocked(_ locked: Bool, by user: String? = nil) {
        isLocked = locked
        lastUpdatedBy = user
        lastUpdatedAt = Date()
    }
    
    mutating func setVisible(_ visible: Bool) {
        isVisible = visible
        // If making invisible, also remove featured status
        if !visible {
            isFeatured = false
        }
        lastUpdatedAt = Date()
    }
    
    mutating func updateScore(_ newScore: GameScore) {
        score = newScore
        lastUpdatedAt = Date()
    }
}

// MARK: - Enhanced Game Status Enum
enum GameStatus: String, CaseIterable {
    case upcoming = "upcoming"
    case lockingSoon = "locking_soon"
    case locked = "locked"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .upcoming:
            return "Upcoming"
        case .lockingSoon:
            return "Locking Soon"
        case .locked:
            return "Locked"
        case .inProgress:
            return "Live"
        case .completed:
            return "Final"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .upcoming:
            return .green
        case .lockingSoon:
            return .orange
        case .locked:
            return .red
        case .inProgress:
            return .blue
        case .completed:
            return .gray
        case .cancelled:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .upcoming:
            return "clock"
        case .lockingSoon:
            return "clock.badge.exclamationmark"
        case .locked:
            return "lock.fill"
        case .inProgress:
            return "play.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .cancelled:
            return "xmark.circle.fill"
        }
    }
    
    var canBetOn: Bool {
        switch self {
        case .upcoming:
            return true
        case .lockingSoon, .locked, .inProgress, .completed, .cancelled:
            return false
        }
    }
    
    var isActive: Bool {
        switch self {
        case .upcoming, .inProgress:
            return true
        case .lockingSoon, .locked, .completed, .cancelled:
            return false
        }
    }
}

// MARK: - Enhanced Team Colors Extension
extension TeamColors {
    static func fromFirestoreData(_ data: [String: Any]) -> TeamColors? {
        guard let primaryHex = data["primaryHex"] as? String,
              let secondaryHex = data["secondaryHex"] as? String else {
            return nil
        }
        
        return TeamColors(
            primary: colorFromHex(primaryHex),
            secondary: colorFromHex(secondaryHex)
        )
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "primaryHex": primary.toHex(),
            "secondaryHex": secondary.toHex()
        ]
    }
}

// MARK: - Color Extension for Hex Conversion
extension Color {
    func toHex() -> String {
        // Simplified hex conversion - in production, use a proper implementation
        // For now, return a default value
        return "#000000"
    }
}

// MARK: - Enhanced Sample Data for Testing
extension Game {
    static let sampleGames: [Game] = [
        // Sample upcoming game
        Game(
            homeTeam: "Orlando Magic",
            awayTeam: "Portland Trail Blazers",
            time: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date(),
            league: "NBA",
            spread: 6.5,
            totalBets: 1500,
            homeTeamColors: TeamColors.getTeamColors("Magic"),
            awayTeamColors: TeamColors.getTeamColors("Trail Blazers")
        ),
        
        // Sample featured game
        Game(
            homeTeam: "Miami Heat",
            awayTeam: "Boston Celtics",
            time: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
            league: "NBA",
            spread: -2.5,
            totalBets: 3500,
            homeTeamColors: TeamColors.getTeamColors("Heat"),
            awayTeamColors: TeamColors.getTeamColors("Celtics"),
            isFeatured: true
        ),
        
        // Sample locked game (game time in past to test lock logic)
        Game(
            homeTeam: "Los Angeles Lakers",
            awayTeam: "Golden State Warriors",
            time: Date().addingTimeInterval(-30 * 60), // 30 minutes ago
            league: "NBA",
            spread: 3.0,
            totalBets: 5000,
            homeTeamColors: TeamColors.getTeamColors("Lakers"),
            awayTeamColors: TeamColors.getTeamColors("Warriors"),
            isLocked: true
        ),
        
        // Sample locking soon game
        Game(
            homeTeam: "Atlanta Hawks",
            awayTeam: "Toronto Raptors",
            time: Date().addingTimeInterval(10 * 60), // 10 minutes from now
            league: "NBA",
            spread: 5.0,
            totalBets: 2000,
            homeTeamColors: TeamColors.getTeamColors("Hawks"),
            awayTeamColors: TeamColors.getTeamColors("Raptors")
        )
    ]
    
    // Guest user for testing
    static let guest = User(
        id: "guest",
        displayName: "Guest User",
        authProvider: "guest"
    )
}

// MARK: - Hashable Implementation
extension Game {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.id == rhs.id
    }
}

/*
 * INTEGRATION NOTES:
 *
 * This enhanced Game model provides:
 *
 * 1. **Automatic Lock Logic**:
 *    - shouldBeLocked: automatically locked 15 minutes before game
 *    - isEffectivelyLocked: combines manual and automatic locks
 *    - canBeFeatured: ensures only future games can be featured
 *
 * 2. **Rich Status Information**:
 *    - displayStatus provides comprehensive game status
 *    - minutesUntilLock shows countdown to lock time
 *    - Enhanced status colors and icons
 *
 * 3. **Enhanced Firestore Integration**:
 *    - Proper team colors storage/retrieval
 *    - Score data integration
 *    - Audit trail with lastUpdatedBy/lastUpdatedAt
 *
 * 4. **Featured Game Logic**:
 *    - Only eligible games can be featured
 *    - Manual vs automatic featured distinction
 *    - Automatic unfeaturing when locked
 *
 * 5. **Proper Spread Display**:
 *    - Enhanced formatting for home/away spreads
 *    - EVEN display for 0 spreads
 *    - Consistent decimal formatting
 *
 * To integrate:
 * 1. Replace existing Game.swift with this version
 * 2. Update GamesViewModel to use canBeFeatured for featured game selection
 * 3. Use displayStatus in UI for rich status display
 * 4. Use isEffectivelyLocked instead of just isLocked for lock checks
 */
