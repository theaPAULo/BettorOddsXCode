//
//  OddsService.swift
//  BettorOdds
//
//  Created by Claude on 6/13/25
//  Version: 2.0.0 - Fixed API endpoint and updated for new Configuration system
//

import Foundation

actor OddsService {
    // MARK: - Properties
    static let shared = OddsService()
    private let apiKey: String
    private let baseURL: String
    
    // MARK: - Initialization
    private init() {
        self.apiKey = AppConfiguration.API.oddsAPIKey
        self.baseURL = AppConfiguration.API.oddsAPIBaseURL
        
        // Validate configuration on initialization
        if apiKey.isEmpty {
            print("⚠️ WARNING: Odds API key is empty. Games will not load.")
        }
    }
    
    // MARK: - API Response Models
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
        let title: String
        let markets: [Market]
    }
    
    struct Market: Codable {
        let key: String
        let outcomes: [Outcome]
    }
    
    struct Outcome: Codable {
        let name: String
        let price: Double
        let point: Double?
    }
    
    // MARK: - Public Methods
    
    /// Fetches games for the specified sport
    /// - Parameter sport: The sport key (e.g., "basketball_nba")
    /// - Returns: Array of Game objects
    func fetchGames(for sport: String = "basketball_nba") async throws -> [Game] {
        // Validate API key
        guard !apiKey.isEmpty else {
            throw OddsServiceError.configurationError("API key is missing")
        }
        
        // Construct the correct endpoint URL
        // Format: https://api.the-odds-api.com/v4/sports/{sport}/odds
        let endpoint = "\(baseURL)/sports/\(sport)/odds"
        
        let queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "regions", value: "us"),
            URLQueryItem(name: "markets", value: "spreads"),
            URLQueryItem(name: "oddsFormat", value: "american"),
            URLQueryItem(name: "dateFormat", value: "iso")
        ]
        
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw OddsServiceError.invalidURL("Failed to create URL components from: \(endpoint)")
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw OddsServiceError.invalidURL("Failed to create URL from components")
        }
        
        print("🌐 Fetching odds from URL: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OddsServiceError.invalidResponse("Invalid HTTP response")
            }
            
            print("📡 API Response Status: \(httpResponse.statusCode)")
            
            // Check API usage headers
            if let remainingRequests = httpResponse.value(forHTTPHeaderField: "x-requests-remaining"),
               let usedRequests = httpResponse.value(forHTTPHeaderField: "x-requests-used") {
                print("📊 API Usage - Remaining: \(remainingRequests), Used: \(usedRequests)")
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200:
                // Success - continue processing
                break
            case 401:
                throw OddsServiceError.authenticationError("Invalid API key")
            case 404:
                throw OddsServiceError.notFound("Sport '\(sport)' not found or no games available")
            case 429:
                throw OddsServiceError.rateLimitExceeded("API rate limit exceeded")
            case 500...599:
                throw OddsServiceError.serverError("Server error: \(httpResponse.statusCode)")
            default:
                throw OddsServiceError.apiError("HTTP \(httpResponse.statusCode)")
            }
            
            // Log response for debugging (first 500 characters)
            if let responseString = String(data: data, encoding: .utf8) {
                let preview = responseString.count > 500 ?
                    String(responseString.prefix(500)) + "..." : responseString
                print("📥 Raw Response Preview: \(preview)")
            }
            
            // Parse the JSON response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let oddsResponse = try decoder.decode([OddsResponse].self, from: data)
            print("📦 Successfully parsed \(oddsResponse.count) games from API")
            
            // Convert API response to Game objects
            let games = oddsResponse.compactMap { response in
                convertToGame(response)
            }
            
            print("✅ Successfully created \(games.count) Game objects")
            return games
            
        } catch let error as OddsServiceError {
            print("❌ OddsService Error: \(error.localizedDescription)")
            throw error
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding Error: \(decodingError)")
            throw OddsServiceError.parsingError("Failed to parse API response: \(decodingError.localizedDescription)")
        } catch let urlError as URLError {
            print("❌ Network Error: \(urlError)")
            throw OddsServiceError.networkError(urlError.localizedDescription)
        } catch {
            print("❌ Unexpected Error: \(error)")
            throw OddsServiceError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Private Methods
    
    /// Converts an OddsResponse to a Game object
    private func convertToGame(_ response: OddsResponse) -> Game? {
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
            totalBets: 0, // This would come from your database
            homeTeamColors: TeamColors.getTeamColors(response.homeTeam),
            awayTeamColors: TeamColors.getTeamColors(response.awayTeam),
            isFeatured: false,
            isVisible: true,
            isLocked: false
        )
        
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
        
        // Default to 0 if no spread found
        return 0.0
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
        default:
            return sportKey.uppercased()
        }
    }
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
    
    var recoverySuggestion: String? {
        switch self {
        case .configurationError:
            return "Check your API key configuration in Configuration.swift"
        case .authenticationError:
            return "Verify your API key is correct and active"
        case .notFound:
            return "Try a different sport or check if games are available"
        case .rateLimitExceeded:
            return "Wait a few minutes before making more requests"
        case .networkError:
            return "Check your internet connection and try again"
        default:
            return "Please try again later or contact support"
        }
    }
}

// MARK: - Configuration Update

/// Extension to provide backward compatibility with existing Configuration class
extension OddsService {
    /// Test method to validate API connectivity
    func testConnection() async -> Bool {
        do {
            let games = try await fetchGames()
            print("✅ API connection test successful - fetched \(games.count) games")
            return true
        } catch {
            print("❌ API connection test failed: \(error.localizedDescription)")
            return false
        }
    }
}
