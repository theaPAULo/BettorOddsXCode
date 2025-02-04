//
//  ScoreService.swift
//  BettorOdds
//
//  Created by Paul Soni on 2/4/25.
//


// ScoreService.swift

import SwiftUI
import FirebaseFirestore

class ScoreService {
    static let shared = ScoreService()
    private let apiKey = "YOUR_API_KEY" // We should move this to a config file
    
    private let baseUrl = "https://api.the-odds-api.com/v4/sports"
    private let gameRepository: GameRepository
    
    private init() {
        self.gameRepository = GameRepository()
    }
    
    func fetchScores(sport: String, daysFrom: Int = 1) async throws {
        print("🎯 Fetching scores for \(sport)")
        
        let url = "\(baseUrl)/\(sport)/scores/?apiKey=\(apiKey)&daysFrom=\(daysFrom)"
        
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let scores = try JSONDecoder().decode([OddsAPIScore].self, from: data)
        
        print("📊 Received \(scores.count) scores from API")
        
        // Process each completed game
        for score in scores where score.completed {
            guard let homeScore = score.scores.first(where: { $0.name == score.homeTeam })?.score,
                  let awayScore = score.scores.first(where: { $0.name == score.awayTeam })?.score,
                  let homeScoreInt = Int(homeScore),
                  let awayScoreInt = Int(awayScore) else {
                print("⚠️ Invalid score data for game \(score.id)")
                continue
            }
            
            let gameScore = GameScore(
                gameId: score.id,
                homeScore: homeScoreInt,
                awayScore: awayScoreInt,
                finalizedAt: score.lastUpdate ?? Date(),
                verifiedAt: nil
            )
            
            try await gameRepository.saveScore(gameScore)
        }
        
        print("✅ Finished processing scores")
    }
}



// Models for The Odds API response
private struct OddsAPIScore: Codable {
    let id: String
    let sportKey: String
    let sportTitle: String
    let commenceTime: Date
    let completed: Bool
    let homeTeam: String
    let awayTeam: String
    let scores: [TeamScore]
    let lastUpdate: Date?
    
    private enum CodingKeys: String, CodingKey {
        case id, completed, scores
        case sportKey = "sport_key"
        case sportTitle = "sport_title"
        case commenceTime = "commence_time"
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case lastUpdate = "last_update"
    }
}

private struct TeamScore: Codable {
    let name: String
    let score: String
}


struct GameScore: Codable {
    let gameId: String
    let homeScore: Int
    let awayScore: Int
    let finalizedAt: Date
    let verifiedAt: Date?
    
    var shouldRemove: Bool {
        // Remove 24 hours after finalization
        return finalizedAt.addingTimeInterval(86400) < Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "gameId": gameId,
            "homeScore": homeScore,
            "awayScore": awayScore,
            "finalizedAt": Timestamp(date: finalizedAt),
            "verifiedAt": verifiedAt.map { Timestamp(date: $0) } as Any
        ]
    }
}

// Add extension for Firestore initialization
extension GameScore {
    static func from(_ snapshot: DocumentSnapshot) -> GameScore? {
        guard let data = snapshot.data() else { return nil }
        
        return GameScore(
            gameId: snapshot.documentID,
            homeScore: data["homeScore"] as? Int ?? 0,
            awayScore: data["awayScore"] as? Int ?? 0,
            finalizedAt: (data["finalizedAt"] as? Timestamp)?.dateValue() ?? Date(),
            verifiedAt: (data["verifiedAt"] as? Timestamp)?.dateValue()
        )
    }
}
