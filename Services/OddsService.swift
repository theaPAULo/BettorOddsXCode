//
//  OddsService.swift
//  BettorOdds
//
//  Version: 2.3.0 - Added NFL support and league filtering
//  Updated: June 2025
//

import Foundation

class OddsService: ObservableObject {
    static let shared = OddsService()
    
    private let apiKey = "YOUR_API_KEY_HERE" // Replace with your actual API key
    private let baseURL = "https://api.the-odds-api.com/v4/sports"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Fetches games for a specific league (NBA or NFL)
    func fetchGames(for league: String = "NBA") async throws -> [Game] {
        let sportKey = mapLeagueToSportKey(league)
        print("🏀 Fetching \(league) games (sport key: \(sportKey))")
        
        guard let url = URL(string: "\(baseURL)/\(sportKey)/odds?regions=us&markets=spreads&oddsFormat=american&apiKey=\(apiKey)") else {
            throw OddsServiceError.invalidURL("Invalid URL for \(league) games")
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OddsServiceError.invalidResponse("Invalid response")
        }
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw OddsServiceError.authenticationError("Invalid API key")
        case 404:
            throw OddsServiceError.notFound("No \(league) games found")
        case 429:
            throw OddsServiceError.rateLimitExceeded("API rate limit exceeded")
        case 500...599:
            throw OddsServiceError.serverError("Server error: \(httpResponse.statusCode)")
        default:
            throw OddsServiceError.apiError("API error: \(httpResponse.statusCode)")
        }
        
        do {
            let oddsResponses = try JSONDecoder().decode([OddsResponse].self, from: data)
            print("✅ Successfully decoded \(oddsResponses.count) \(league) games")
            
            let games = oddsResponses.compactMap { response in
                convertToGame(from: response)
            }
            
            print("🎮 Converted to \(games.count) valid \(league) games")
            return games
            
        } catch {
            print("❌ Decoding error: \(error)")
            throw OddsServiceError.parsingError("Failed to parse \(league) games data: \(error.localizedDescription)")
        }
    }
    
    /// Convenience method for backward compatibility
    func fetchGames() async throws -> [Game] {
        return try await fetchGames(for: "NBA")
    }
    
    // MARK: - Private Methods
    
    /// Maps league display name to The Odds API sport key
    private func mapLeagueToSportKey(_ league: String) -> String {
        switch league.uppercased() {
        case "NBA":
            return "basketball_nba"
        case "NFL":
            return "americanfootball_nfl"
        case "MLB":
            return "baseball_mlb"
        case "NHL":
            return "icehockey_nhl"
        case "NCAAB":
            return "basketball_ncaab"
        case "NCAAF":
            return "americanfootball_ncaaf"
        default:
            print("⚠️ Unknown league '\(league)', defaulting to NBA")
            return "basketball_nba"
        }
    }
    
    /// Converts API response to internal Game model
    private func convertToGame(from response: OddsResponse) -> Game? {
        // Validate required fields
        guard !response.homeTeam.isEmpty,
              !response.awayTeam.isEmpty else {
            print("⚠️ Skipping game with missing team names")
            return nil
        }
        
        // Find the spread for the home team
        let spread = extractSpread(from: response)
        
        // Determine league from sport key
        let league = mapSportKeyToLeague(response.sportKey)
        
        // Create the game
        let game = Game(
            id: response.id,
            homeTeam: response.homeTeam,
            awayTeam: response.awayTeam,
            time: response.commenceTime,
            league: league,
            spread: spread,
            totalBets: Int.random(in: 100...5000), // Simulate bet volume
            homeTeamColors: TeamColors.getTeamColors(response.homeTeam),
            awayTeamColors: TeamColors.getTeamColors(response.awayTeam),
            isFeatured: false,
            isVisible: true,
            isLocked: false
        )
        
        print("🎯 Created game: \(game.awayTeam) @ \(game.homeTeam) (\(league))")
        return game
    }
    
    /// Extracts the spread from bookmaker data
    private func extractSpread(from response: OddsResponse) -> Double {
        // Look for spread market in bookmakers
        for bookmaker in response.bookmakers {
            for market in bookmaker.markets {
                if market.key == "spreads" {
                    // Find the home team outcome
                    if let homeOutcome = market.outcomes.first(where: { $0.name == response.homeTeam }),
                       let spread = homeOutcome.point {
                        return spread
                    }
                }
            }
        }
        
        // Generate realistic spread if none found
        let randomSpread = Double.random(in: -14.0...14.0)
        let roundedSpread = (randomSpread * 2).rounded() / 2 // Round to nearest 0.5
        print("ℹ️ No spread found for \(response.awayTeam) @ \(response.homeTeam), using: \(roundedSpread)")
        return roundedSpread
    }
    
    /// Maps sport key to league display name
    private func mapSportKeyToLeague(_ sportKey: String) -> String {
        switch sportKey {
        case "basketball_nba":
            return "NBA"
        case "americanfootball_nfl":
            return "NFL"
        case "baseball_mlb":
            return "MLB"
        case "icehockey_nhl":
            return "NHL"
        case "basketball_ncaab":
            return "NCAAB"
        case "americanfootball_ncaaf":
            return "NCAAF"
        default:
            return sportKey.uppercased()
        }
    }
}

// MARK: - Data Models

struct OddsResponse: Codable {
    let id: String
    let sportKey: String
    let homeTeam: String
    let awayTeam: String
    let commenceTime: Date
    let bookmakers: [Bookmaker]
    
    enum CodingKeys: String, CodingKey {
        case id
        case sportKey = "sport_key"
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case commenceTime = "commence_time"
        case bookmakers
    }
}

struct Bookmaker: Codable {
    let key: String
    let title: String
    let markets: [Market]
}

struct Market: Codable {
    let key: String
    let outcomes: [Outcome]
}

struct Outcome: Codable {
    let name: String
    let price: Int?
    let point: Double?
}

// MARK: - Error Handling

enum OddsServiceError: LocalizedError {
    case configurationError(String)
    case invalidURL(String)
    case invalidResponse(String)
    case authenticationError(String)
    case notFound(String)
    case rateLimitExceeded(String)
    case serverError(String)
    case apiError(String)
    case parsingError(String)
    case networkError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        case .invalidURL(let message):
            return "Invalid URL: \(message)"
        case .invalidResponse(let message):
            return "Invalid Response: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .notFound(let message):
            return "Not Found: \(message)"
        case .rateLimitExceeded(let message):
            return "Rate Limit Exceeded: \(message)"
        case .serverError(let message):
            return "Server Error: \(message)"
        case .apiError(let message):
            return "API Error: \(message)"
        case .parsingError(let message):
            return "Parsing Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .unknown(let message):
            return "Unknown Error: \(message)"
        }
    }
}
