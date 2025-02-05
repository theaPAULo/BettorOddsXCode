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
    // MARK: - Properties
    static let shared = ScoreService()
    private let apiKey = "aec5b19b654411a05206d9d67dfb7764" // We should move this to a config file
    private let baseUrl = "https://api.the-odds-api.com/v4/sports"
    private let db = FirebaseConfig.shared.db
    
    // MARK: - Methods
    func fetchScores(sport: String, daysFrom: Int = 1) async throws {
        print("🎯 Fetching scores for \(sport)")
        
        let url = "\(baseUrl)/\(sport)/scores/?apiKey=\(apiKey)&daysFrom=\(daysFrom)"
        
        guard let url = URL(string: url) else {
            throw ScoreError.apiError("Invalid URL")
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Log API usage and response
        if let httpResponse = response as? HTTPURLResponse {
            print("""
                📊 API Response Headers:
                - Remaining requests: \(httpResponse.value(forHTTPHeaderField: "x-requests-remaining") ?? "unknown")
                - Requests used: \(httpResponse.value(forHTTPHeaderField: "x-requests-used") ?? "unknown")
                """)
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw ScoreError.apiError("API returned status code \(httpResponse.statusCode)")
            }
        }
        
        // Debug: Print raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📝 Raw API Response: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601  // Add this line for date parsing
        
        do {
            let scores = try decoder.decode([OddsAPIScore].self, from: data)
            print("📦 Received \(scores.count) games from API")
            
            // Process completed games
            for score in scores where score.completed {
                // Skip if no scores available
                guard let gameScores = score.scores else {
                    print("⚠️ No scores available for game \(score.id)")
                    continue
                }
                
                guard let homeScore = gameScores.first(where: { $0.name == score.homeTeam })?.score,
                      let awayScore = gameScores.first(where: { $0.name == score.awayTeam })?.score,
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
                
                try await db.collection("scores").document(score.id).setData(gameScore.toDictionary())
                print("✅ Saved score for \(score.homeTeam) vs \(score.awayTeam): \(homeScoreInt)-\(awayScoreInt)")
            }
            
            print("✅ Finished processing scores")
        } catch {
            print("❌ Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    print("Key not found: \(key.stringValue) - \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch: expected \(type) - \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value not found: expected \(type) - \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error")
                }
            }
            throw error
        }
    }
    
    // MARK: - Errors
    enum ScoreError: Error {
        case invalidScoreData
        case apiError(String)
        
        var localizedDescription: String {
            switch self {
            case .invalidScoreData:
                return "Invalid score data received"
            case .apiError(let message):
                return "API Error: \(message)"
            }
        }
    }
}

// Rest of your models remain the same...



// Models for The Odds API response
private struct OddsAPIScore: Codable {
    let id: String
    let sportKey: String
    let sportTitle: String
    let commenceTime: Date
    let completed: Bool
    let homeTeam: String
    let awayTeam: String
    let scores: [TeamScore]?  // Make optional
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
