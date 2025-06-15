//
//  OddsService.swift - Fixed API Key
//  BettorOdds
//
//  Version: 2.3.1 - Fixed API key to use working key from Configuration
//

import Foundation

class OddsService: ObservableObject {
    static let shared = OddsService()
    
    // FIXED: Use the working API key from Configuration instead of placeholder
    private let apiKey = Configuration.API.oddsAPIKey
    private let baseURL = "https://api.the-odds-api.com/v4/sports"
    
    private init() {
        // Validate API key on initialization
        if apiKey.isEmpty || apiKey.contains("YOUR_API_KEY_HERE") {
            print("⚠️ WARNING: Invalid API key in OddsService. Please check Configuration.swift")
        } else {
            print("✅ OddsService initialized with valid API key")
        }
    }
    
    // MARK: - Public Methods
    
    /// Fetches games for a specific league (NBA or NFL)
    func fetchGames(for league: String = "NBA") async throws -> [Game] {
        let sportKey = mapLeagueToSportKey(league)
        print("🏀 Fetching \(league) games (sport key: \(sportKey))")
        print("🔑 Using API key: \(apiKey.prefix(8))...") // Log first 8 chars for debugging
        
        guard let url = URL(string: "\(baseURL)/\(sportKey)/odds?regions=us&markets=spreads&oddsFormat=american&apiKey=\(apiKey)") else {
            throw OddsServiceError.invalidURL("Invalid URL for \(league) games")
        }
        
        print("🌐 Fetching from URL: \(url)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OddsServiceError.invalidResponse("Invalid response")
        }
        
        print("📡 HTTP Status: \(httpResponse.statusCode)")
        
        // Log API usage headers if available
        if let remaining = httpResponse.value(forHTTPHeaderField: "x-requests-remaining"),
           let used = httpResponse.value(forHTTPHeaderField: "x-requests-used") {
            print("📊 API Usage - Remaining: \(remaining), Used: \(used)")
        }
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            print("❌ 401 Unauthorized - API key is invalid or expired")
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
        // Extract the spread from bookmakers
        var spread: Double = 0.0
        
        for bookmaker in response.bookmakers {
            for market in bookmaker.markets {
                if market.key == "spreads" {
                    // Look for the home team spread
                    if let homeOutcome = market.outcomes.first(where: { $0.name == response.homeTeam }),
                       let homeSpread = homeOutcome.point {
                        spread = homeSpread
                        break
                    }
                }
            }
            if spread != 0.0 { break }
        }
        
        // Convert to internal Game model
        let game = Game(
            id: response.id,
            homeTeam: response.homeTeam,
            awayTeam: response.awayTeam,
            time: response.commenceTime,
            league: mapSportKeyToLeague(response.sportKey),
            spread: spread,
            totalBets: 0, // Default value
            homeTeamColors: TeamColors.getTeamColors(response.homeTeam),
            awayTeamColors: TeamColors.getTeamColors(response.awayTeam),
            isFeatured: false,
            isVisible: true,
            isLocked: false
        )
        
        return game
    }
    
    /// Maps sport key back to league display name
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

