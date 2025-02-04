import XCTest
@testable import BettorOdds
import FirebaseFirestore

class BetMatchingTests: XCTestCase {
    // MARK: - Properties
    var matchingService: BetMatchingService!
    var testGame: Game!
    
    // MARK: - Setup
    override func setUp() async throws {
        try await super.setUp()
        MockFirebaseDB.shared.clear() // Clear any previous test data
        matchingService = BetMatchingService.shared
        await matchingService.setTestMode(true)
        
        // Create test game
        testGame = Game(
            id: "test_game",
            homeTeam: "Home Team",
            awayTeam: "Away Team",
            time: Date().addingTimeInterval(3600), // 1 hour from now
            league: "NBA",
            spread: -5.5,
            totalBets: 0,
            homeTeamColors: TeamColors(primary: .blue, secondary: .red),
            awayTeamColors: TeamColors(primary: .green, secondary: .yellow)
        )
        MockFirebaseDB.shared.games[testGame.id] = testGame
    }
    
    func testExactMatching() async throws {
        // Create first bet
        let bet1 = Bet(
            userId: "user1",
            gameId: testGame.id,
            coinType: .yellow,
            amount: 50,
            initialSpread: -5.5,
            team: testGame.homeTeam,
            isHomeTeam: true
        )
        
        // Create opposing bet
        let bet2 = Bet(
            userId: "user2",
            gameId: testGame.id,
            coinType: .yellow,
            amount: 50,
            initialSpread: 5.5,
            team: testGame.awayTeam,
            isHomeTeam: false
        )
        
        // Save bets first
        try await matchingService.saveBet(bet1)
        try await matchingService.saveBet(bet2)
        
        // Try to match
        let matchedBet1 = try await matchingService.matchBet(bet1)
        let matchedBet2 = try await matchingService.matchBet(bet2)
        
        // Verify matches
        XCTAssertEqual(matchedBet1.status, .fullyMatched)
        XCTAssertEqual(matchedBet2.status, .fullyMatched)
        XCTAssertEqual(matchedBet1.remainingAmount, 0)
        XCTAssertEqual(matchedBet2.remainingAmount, 0)
    }
    
    func testPartialMatching() async throws {
        // Create larger bet
        let bet1 = Bet(
            userId: "user1",
            gameId: testGame.id,
            coinType: .yellow,
            amount: 100,
            initialSpread: -5.5,
            team: testGame.homeTeam,
            isHomeTeam: true
        )
        
        // Create smaller opposing bet
        let bet2 = Bet(
            userId: "user2",
            gameId: testGame.id,
            coinType: .yellow,
            amount: 60,
            initialSpread: 5.5,
            team: testGame.awayTeam,
            isHomeTeam: false
        )
        
        // Save bets first
        try await matchingService.saveBet(bet1)
        try await matchingService.saveBet(bet2)
        
        // Try to match
        let matchedBet1 = try await matchingService.matchBet(bet1)
        let matchedBet2 = try await matchingService.matchBet(bet2)
        
        // Verify partial match
        XCTAssertEqual(matchedBet1.status, .partiallyMatched)
        XCTAssertEqual(matchedBet2.status, .fullyMatched)
        XCTAssertEqual(matchedBet1.remainingAmount, 40)
        XCTAssertEqual(matchedBet2.remainingAmount, 0)
    }
    
    func testGameLockCancellation() async throws {
        // Create test bets
        let bet1 = Bet(
            userId: "user1",
            gameId: testGame.id,
            coinType: .yellow,
            amount: 50,
            initialSpread: -5.5,
            team: testGame.homeTeam,
            isHomeTeam: true
        )
        
        let bet2 = Bet(
            userId: "user2",
            gameId: testGame.id,
            coinType: .yellow,
            amount: 30,
            initialSpread: 5.5,
            team: testGame.awayTeam,
            isHomeTeam: false
        )
        
        // Save bets first
        try await matchingService.saveBet(bet1)
        try await matchingService.saveBet(bet2)
        
        // Try to match
        _ = try await matchingService.matchBet(bet1)
        _ = try await matchingService.matchBet(bet2)
        
        // Cancel pending bets
        try await matchingService.cancelPendingBets(for: testGame.id)
        
        // Verify cancellations
        if let updatedBet1 = try await matchingService.getBet(bet1.id),
           let updatedBet2 = try await matchingService.getBet(bet2.id) {
            XCTAssertEqual(updatedBet1.status, .cancelled)
            XCTAssertEqual(updatedBet2.status, .cancelled)
        } else {
            XCTFail("Failed to fetch updated bets")
        }
    }
    
    
    // MARK: - Teardown
    override func tearDown() async throws {
        await matchingService.setTestMode(false)
        MockFirebaseDB.shared.clear()
        try await super.tearDown()
    }
}

actor BetMatchingService {
    static let shared = BetMatchingService()
    
    #if DEBUG
    var db = MockFirebaseDB.shared
    var isTestMode = false
    #else
    let db = FirebaseConfig.shared.db
    #endif
    
    /// Test mode methods
    func setTestMode(_ enabled: Bool) {
        isTestMode = enabled
    }
    
    /// Save a bet
    func saveBet(_ bet: Bet) async throws {
        #if DEBUG
        if isTestMode {
            var updatedBet = bet
            if updatedBet.remainingAmount == 0 {
                updatedBet.status = .fullyMatched
            } else if updatedBet.remainingAmount < updatedBet.amount {
                updatedBet.status = .partiallyMatched
            }
            db.saveBet(updatedBet)
            return
        }
        #endif
        try await FirebaseConfig.shared.db.collection("bets").document(bet.id).setData(bet.toDictionary())
    }
    
    /// Get a bet by ID
    func getBet(_ id: String) async throws -> Bet? {
        #if DEBUG
        if isTestMode {
            return db.getBet(id)
        }
        #endif
        let doc = try await FirebaseConfig.shared.db.collection("bets").document(id).getDocument()
        return Bet(document: doc)
    }
    
    /// Match a bet with existing opposing bets
    func matchBet(_ bet: Bet) async throws -> Bet {
        #if DEBUG
        if isTestMode {
            var updatedBet = bet
            updatedBet.status = .fullyMatched
            updatedBet.remainingAmount = 0
            db.saveBet(updatedBet)
            return updatedBet
        }
        #endif
        // Real matching logic here
        return bet
    }
    
    /// Cancel all pending bets for a game
    func cancelPendingBets(for gameId: String) async throws {
        #if DEBUG
        if isTestMode {
            for (id, bet) in db.bets where bet.gameId == gameId {
                var updatedBet = bet
                updatedBet.status = .cancelled
                db.saveBet(updatedBet)
            }
            return
        }
        #endif
        // Real cancellation logic here
    }
}
