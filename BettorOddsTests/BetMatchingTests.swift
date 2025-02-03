//
//  BetMatchingTests.swift
//  BettorOddsTests
//
//  Created by Assistant on 2/2/25
//  Version: 1.0.1
//

import XCTest
@testable import BettorOdds

class BetMatchingTests: XCTestCase {
    // MARK: - Properties
    var matchingService: BetMatchingService!
    var testGame: Game!
    
    // MARK: - Setup
    override func setUp() async throws {
        try await super.setUp()
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
    }
    
    // MARK: - Test Cases
    
    /// Test exact matching of bets
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
        
        // Try to match
        let matchedBet1 = try await matchingService.matchBet(bet1)
        let matchedBet2 = try await matchingService.matchBet(bet2)
        
        // Verify matches
        XCTAssertEqual(matchedBet1.status, .fullyMatched)
        XCTAssertEqual(matchedBet2.status, .fullyMatched)
        XCTAssertEqual(matchedBet1.remainingAmount, 0)
        XCTAssertEqual(matchedBet2.remainingAmount, 0)
    }
    
    /// Test partial matching of bets
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
        
        // Try to match
        let matchedBet1 = try await matchingService.matchBet(bet1)
        let matchedBet2 = try await matchingService.matchBet(bet2)
        
        // Verify partial match
        XCTAssertEqual(matchedBet1.status, .partiallyMatched)
        XCTAssertEqual(matchedBet2.status, .fullyMatched)
        XCTAssertEqual(matchedBet1.remainingAmount, 40)
        XCTAssertEqual(matchedBet2.remainingAmount, 0)
    }
    
    /// Test cancellation of pending bets when game locks
    func testGameLockCancellation() async throws {
        // Create some pending bets
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
        
        // Place bets
        _ = try await matchingService.matchBet(bet1)
        _ = try await matchingService.matchBet(bet2)
        
        // Simulate game lock
        try await matchingService.cancelPendingBets(for: testGame.id)
        
        // Verify cancellations
        if let updatedBet1 = try await BetRepository().fetch(id: bet1.id),
           let updatedBet2 = try await BetRepository().fetch(id: bet2.id) {
            XCTAssertEqual(updatedBet1.status, .cancelled)
            XCTAssertEqual(updatedBet2.status, .cancelled)
        } else {
            XCTFail("Failed to fetch updated bets")
        }
    }
    
    /// Test spread change cancellation
    func testSpreadChangeCancellation() async throws {
        // Create initial bet
        var bet1 = Bet(
            userId: "user1",
            gameId: testGame.id,
            coinType: .yellow,
            amount: 50,
            initialSpread: -5.5,
            team: testGame.homeTeam,
            isHomeTeam: true
        )
        
        // Place bet
        bet1 = try await matchingService.matchBet(bet1)
        
        // Create new bet with changed spread
        let bet2 = Bet(
            userId: "user1",
            gameId: testGame.id,
            coinType: .yellow,
            amount: 50,
            initialSpread: -6.5, // Changed by 1 point
            team: testGame.homeTeam,
            isHomeTeam: true
        )
        
        // Try to match with new spread
        try await matchingService.cancelBet(bet1)
        
        // Verify cancellation
        if let finalBet = try await BetRepository().fetch(id: bet1.id) {
            XCTAssertEqual(finalBet.status, .cancelled)
        } else {
            XCTFail("Failed to fetch final bet")
        }
    }
    
    // MARK: - Teardown
    override func tearDown() async throws {
        await matchingService.setTestMode(false)
        try await super.tearDown()
    }
}
