//
//  Fixed JSON Decoding for OddsService
//  BettorOdds
//
//  Version: 2.4.1 - Fixed commence_time parsing issue
//

import Foundation

// UPDATED: OddsResponse with proper date handling
struct OddsResponse: Codable {
    let id: String
    let sportKey: String
    let homeTeam: String
    let awayTeam: String
    let commenceTime: Date  // This will be properly decoded as Date
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

// UPDATED: OddsService with proper date decoding
class OddsService: ObservableObject {
    static let shared = OddsService()
    
    private let apiKey = "a2358fa8aa8f101a940462e5d0f13581"
    private let baseURL = "https://api.the-odds-api.com/v4/sports"
    
    private init() {
        print("🔑 OddsService initialized with correct key: \(apiKey.prefix(8))...")
    }
    
    // MARK: - Public Methods
    
    func fetchGames(for league: String = "NBA") async throws -> [Game] {
        let sportKey = mapLeagueToSportKey(league)
        print("🏀 Fetching \(league) games (sport key: \(sportKey))")
        
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
            print("✅ SUCCESS! API key is working correctly")
            break
        case 401:
            print("❌ 401 Unauthorized - Check if this key has odds access")
            throw OddsServiceError.authenticationError("Invalid API key or insufficient permissions")
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
            // FIXED: Proper date decoding strategy
            let decoder = JSONDecoder()
            
            // The Odds API returns dates in ISO8601 format as strings
            decoder.dateDecodingStrategy = .iso8601
            
            // Log raw response for debugging (first 500 chars)
            if let jsonString = String(data: data, encoding: .utf8) {
                let preview = jsonString.count > 500 ? String(jsonString.prefix(500)) + "..." : jsonString
                print("📝 Raw JSON Preview: \(preview)")
            }
            
            let oddsResponses = try decoder.decode([OddsResponse].self, from: data)
            print("✅ Successfully decoded \(oddsResponses.count) \(league) games")
            
            let games = oddsResponses.compactMap { response in
                convertToGame(from: response)
            }
            
            print("🎮 Converted to \(games.count) valid \(league) games")
            return games
            
        } catch let DecodingError.typeMismatch(type, context) {
            print("❌ Type mismatch error:")
            print("   Expected: \(type)")
            print("   Path: \(context.codingPath)")
            print("   Description: \(context.debugDescription)")
            
            // Try alternative date decoding strategies
            return try await parseWithAlternativeStrategy(data: data, league: league)
            
        } catch let DecodingError.keyNotFound(key, context) {
            print("❌ Key not found: \(key)")
            print("   Path: \(context.codingPath)")
            throw OddsServiceError.parsingError("Missing required field: \(key)")
            
        } catch {
            print("❌ General decoding error: \(error)")
            throw OddsServiceError.parsingError("Failed to parse \(league) games data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Alternative Parsing Strategy
    
    private func parseWithAlternativeStrategy(data: Data, league: String) async throws -> [Game] {
        print("🔄 Trying alternative date parsing strategies...")
        
        // Strategy 1: Try different date formats
        let strategies: [JSONDecoder.DateDecodingStrategy] = [
            .secondsSince1970,
            .millisecondsSince1970,
            .formatted(DateFormatter.iso8601Full),
            .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Try multiple date formats
                let formatters = [
                    DateFormatter.iso8601Full,
                    DateFormatter.iso8601,
                    DateFormatter.oddsAPI
                ]
                
                for formatter in formatters {
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
            }
        ]
        
        for (index, strategy) in strategies.enumerated() {
            do {
                print("🧪 Trying date strategy \(index + 1)...")
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = strategy
                
                let oddsResponses = try decoder.decode([OddsResponse].self, from: data)
                print("✅ Success with strategy \(index + 1)! Decoded \(oddsResponses.count) games")
                
                let games = oddsResponses.compactMap { response in
                    convertToGame(from: response)
                }
                
                return games
                
            } catch {
                print("❌ Strategy \(index + 1) failed: \(error.localizedDescription)")
                continue
            }
        }
        
        throw OddsServiceError.parsingError("All date parsing strategies failed for \(league)")
    }
    
    func fetchGames() async throws -> [Game] {
        return try await fetchGames(for: "NBA")
    }
    
    // MARK: - Private Methods
    
    private func mapLeagueToSportKey(_ league: String) -> String {
        switch league.uppercased() {
        case "NBA": return "basketball_nba"
        case "NFL": return "americanfootball_nfl"
        case "MLB": return "baseball_mlb"
        case "NHL": return "icehockey_nhl"
        default:
            print("⚠️ Unknown league '\(league)', defaulting to NBA")
            return "basketball_nba"
        }
    }
    
    private func convertToGame(from response: OddsResponse) -> Game? {
        var spread: Double = 0.0
        
        for bookmaker in response.bookmakers {
            for market in bookmaker.markets {
                if market.key == "spreads" {
                    if let homeOutcome = market.outcomes.first(where: { $0.name == response.homeTeam }),
                       let homeSpread = homeOutcome.point {
                        spread = homeSpread
                        break
                    }
                }
            }
            if spread != 0.0 { break }
        }
        
        return Game(
            id: response.id,
            homeTeam: response.homeTeam,
            awayTeam: response.awayTeam,
            time: response.commenceTime,
            league: mapSportKeyToLeague(response.sportKey),
            spread: spread,
            totalBets: 0,
            homeTeamColors: TeamColors.getTeamColors(response.homeTeam),
            awayTeamColors: TeamColors.getTeamColors(response.awayTeam),
            isFeatured: false,
            isVisible: true,
            isLocked: false
        )
    }
    
    private func mapSportKeyToLeague(_ sportKey: String) -> String {
        switch sportKey {
        case "basketball_nba": return "NBA"
        case "americanfootball_nfl": return "NFL"
        case "baseball_mlb": return "MLB"
        case "icehockey_nhl": return "NHL"
        default: return sportKey.uppercased()
        }
    }
}

// MARK: - Date Formatter Extensions

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static let oddsAPI: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

// Keep your existing error types unchanged
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
