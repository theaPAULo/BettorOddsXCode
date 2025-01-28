import Foundation
import FirebaseFirestore

actor GameService {
    private let db = FirebaseConfig.shared.db
    
    /// Fetches a specific game
    func fetchGame(gameId: String) async throws -> Game {
        let document = try await db.collection("games").document(gameId).getDocument()
        
        guard document.exists else {
            throw DatabaseError.documentNotFound
        }
        
        let data = document.data() ?? [:]
        
        guard let id = data["id"] as? String,
              let homeTeam = data["homeTeam"] as? String,
              let awayTeam = data["awayTeam"] as? String,
              let time = (data["time"] as? Timestamp)?.dateValue(),
              let league = data["league"] as? String,
              let spread = data["spread"] as? Double,
              let totalBets = data["totalBets"] as? Int else {
            throw DatabaseError.documentNotFound
        }
        
        return Game(
            id: id,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            time: time,
            league: league,
            spread: spread,
            totalBets: totalBets,
            homeTeamColors: TeamColors.getTeamColors(homeTeam),
            awayTeamColors: TeamColors.getTeamColors(awayTeam)
        )
    }
    
    /// Fetches games for a specific league
    func fetchGames(league: String) async throws -> [Game] {
        let snapshot = try await db.collection("games")
            .whereField("league", isEqualTo: league)
            .order(by: "time")
            .getDocuments()
        
        return try snapshot.documents.map { document -> Game in
            let data = document.data()
            guard let id = data["id"] as? String,
                  let homeTeam = data["homeTeam"] as? String,
                  let awayTeam = data["awayTeam"] as? String,
                  let time = (data["time"] as? Timestamp)?.dateValue(),
                  let league = data["league"] as? String,
                  let spread = data["spread"] as? Double,
                  let totalBets = data["totalBets"] as? Int else {
                throw DatabaseError.documentNotFound
            }
            
            return Game(
                id: id,
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                time: time,
                league: league,
                spread: spread,
                totalBets: totalBets,
                homeTeamColors: TeamColors.getTeamColors(homeTeam),
                awayTeamColors: TeamColors.getTeamColors(awayTeam)
            )
        }
    }
    
    /// Saves a game to the database
    func saveGame(_ game: Game) async throws {
        let gameData: [String: Any] = [
            "id": game.id,
            "homeTeam": game.homeTeam,
            "awayTeam": game.awayTeam,
            "time": game.time,
            "league": game.league,
            "spread": game.spread,
            "totalBets": game.totalBets
        ]
        
        try await db.collection("games").document(game.id).setData(gameData, merge: true)
    }
    
    /// Sets up a real-time listener for game updates
    func listenToGameUpdates(
        gameId: String,
        handler: @escaping (Game?) -> Void
    ) -> ListenerRegistration {
        let ref = db.collection("games").document(gameId)
        
        return ref.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self,
                  let document = documentSnapshot,
                  document.exists else {
                handler(nil)
                return
            }
            
            Task {
                do {
                    let game = try await self.fetchGame(gameId: gameId)
                    handler(game)
                } catch {
                    handler(nil)
                }
            }
        }
    }
}
