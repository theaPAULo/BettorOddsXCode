import XCTest
@testable import BettorOdds
import FirebaseFirestore

class MockFirebaseDB {
    static var shared = MockFirebaseDB()
    var bets: [String: Bet] = [:]
    var games: [String: Game] = [:]
    var isTestMode = true
    
    func saveBet(_ bet: Bet) {
        bets[bet.id] = bet
    }
    
    func getBet(_ id: String) -> Bet? {
        return bets[id]
    }
    
    func clear() {
        bets = [:]
        games = [:]
    }
}
