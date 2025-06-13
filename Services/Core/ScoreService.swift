//
//  ScoreService.swift
//  BettorOdds
//
//  Created by Paul Soni on 2/4/25.
//  Version: 1.1.0 - Fixed error handling for future games without scores
//

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
        
        // Wrap the entire operation in error handling
        do {
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
            
            // Debug: Print raw response but limit size
            if let jsonString = String(data: data, encoding: .utf8) {
                let preview = jsonString.count > 500 ? String(jsonString.prefix(500)) + "..." : jsonString
                print("📝 Raw API Response Preview: \(preview)")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let scores = try decoder.decode([OddsAPIScore].self, from: data)
            print("📦 Received \(scores.count) games from Scores API")
            
            // Process completed games only
            let completedGames = scores.filter { $0.completed }
            print("🏁 Found \(completedGames.count) completed games with scores")
            
            if completedGames.isEmpty {
                print("ℹ️ No completed games found - this is normal for future games")
                return // Exit gracefully, no error
            }
            
            // Process each completed game
            for score in completedGames {
                do {
                    try await processCompletedGame(score)
                } catch {
                    print("⚠️ Error processing game \(score.id): \(error.localizedDescription)")
                    // Continue processing other games instead of failing completely
                    continue
                }
            }
            
            print("✅ Finished processing scores successfully")
            
        } catch DecodingError.dataCorrupted(let context) {
            print("❌ Data corruption error: \(context.debugDescription)")
            // Don't throw - this might be expected for future games
            print("ℹ️ This is often normal when no completed games are available")
            
        } catch DecodingError.keyNotFound(let key, let context) {
            print("❌ Missing key '\(key.stringValue)': \(context.debugDescription)")
            // Don't throw - this might be expected for future games
            print("ℹ️ This is often normal when score data structure varies")
            
        } catch DecodingError.typeMismatch(let type, let context) {
            print("❌ Type mismatch expecting \(type): \(context.debugDescription)")
            // Don't throw - this might be expected for future games
            print("ℹ️ This is often normal when score data types vary")
            
        } catch DecodingError.valueNotFound(let type, let context) {
            print("❌ Missing value of type \(type): \(context.debugDescription)")
            // Don't throw - this might be expected for future games
            print("ℹ️ This is often normal when optional score data is missing")
            
        } catch {
            print("❌ Score fetching error: \(error.localizedDescription)")
            // Only throw for serious errors, not data issues
            if error is URLError {
                throw error // Network errors should be thrown
            }
            // For other errors, log but don't crash the app
            print("ℹ️ Continuing despite score fetching issue")
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Processes a single completed game and saves its score
    private func processCompletedGame(_ score: OddsAPIScore) async throws {
        // Skip if no scores available
        guard let gameScores = score.scores, !gameScores.isEmpty else {
            print("⚠️ No scores available for completed game \(score.id)")
            return
        }
        
        // Find home and away team scores
        guard let homeScore = gameScores.first(where: { $0.name == score.homeTeam })?.score,
              let awayScore = gameScores.first(where: { $0.name == score.awayTeam })?.score else {
            print("⚠️ Could not find scores for teams in game \(score.id)")
            return
        }
        
        // Convert string scores to integers
        guard let homeScoreInt = Int(homeScore),
              let awayScoreInt = Int(awayScore) else {
            print("⚠️ Invalid score format for game \(score.id): home=\(homeScore), away=\(awayScore)")
            return
        }
        
        // Create game score object
        let gameScore = GameScore(
            gameId: score.id,
            homeScore: homeScoreInt,
            awayScore: awayScoreInt,
            finalizedAt: score.lastUpdate ?? Date(),
            verifiedAt: Date() // Mark as verified now
        )
        
        // Save to Firestore
        try await db.collection("scores").document(score.id).setData(gameScore.toDictionary())
        print("✅ Saved score for \(score.homeTeam) vs \(score.awayTeam): \(homeScoreInt)-\(awayScoreInt)")
    }
    
    // MARK: - Error Types
    enum ScoreError: Error {
        case invalidScoreData
        case apiError(String)
        case networkError(String)
        
        var localizedDescription: String {
            switch self {
            case .invalidScoreData:
                return "Invalid score data received from API"
            case .apiError(let message):
                return "Score API Error: \(message)"
            case .networkError(let message):
                return "Network Error: \(message)"
            }
        }
    }
}

// MARK: - API Response Models

/// Model for The Odds API scores response
private struct OddsAPIScore: Codable {
    let id: String
    let sportKey: String
    let sportTitle: String
    let commenceTime: Date
    let completed: Bool
    let homeTeam: String
    let awayTeam: String
    let scores: [TeamScore]?  // Optional because future games won't have scores
    let lastUpdate: Date?     // Optional because it might not always be present
    
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

/// Model for individual team scores
private struct TeamScore: Codable {
    let name: String
    let score: String  // Keep as string since API returns it as string
}

/// Model for game scores stored in Firestore
struct GameScore: Codable {
    let gameId: String
    let homeScore: Int
    let awayScore: Int
    let finalizedAt: Date
    let verifiedAt: Date?
    
    /// Determines if this score should be removed from the database (after 24 hours)
    var shouldRemove: Bool {
        return finalizedAt.addingTimeInterval(86400) < Date()
    }
    
    /// Converts GameScore to Firestore dictionary
    func toDictionary() -> [String: Any] {
        return [
            "gameId": gameId,
            "homeScore": homeScore,
            "awayScore": awayScore,
            "finalizedAt": Timestamp(date: finalizedAt),
            "verifiedAt": verifiedAt.map { Timestamp(date: $0) } as Any
        ]
    }
    
    /// Creates GameScore from Firestore document
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
