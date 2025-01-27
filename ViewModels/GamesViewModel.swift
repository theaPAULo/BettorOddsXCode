//
//  GamesViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//

import Foundation
import Combine

class GamesViewModel: ObservableObject {
    @Published private(set) var games: [Game] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var balance: Double = 1000.0  // Example balance
    @Published private(set) var dailyBetsTotal: Double = 0  // Track daily betting total
    
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadGames()
        setupUpdateTimer()
    }
    
    func loadGames() {
        isLoading = true
        
        // Simulate API call - replace with real API call later
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.games = Game.sampleGames
            self?.isLoading = false
        }
    }
    
    func refreshGames() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            loadGames()
        }
    }
    
    private func setupUpdateTimer() {
        // Update odds every 5 minutes
        updateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.updateOdds()
        }
    }
    
    private func updateOdds() {
        // Simulate odds updates - replace with real API call later
        games = games.map { game in
            var updatedGame = game
            // Randomly adjust spread by -0.5 to +0.5
            let adjustment = Double.random(in: -0.5...0.5)
            let newSpread = game.spread + adjustment
            // Create new game with updated spread
            return Game(
                id: game.id,
                homeTeam: game.homeTeam,
                awayTeam: game.awayTeam,
                time: game.time,
                league: game.league,
                spread: newSpread,
                totalBets: game.totalBets,
                homeTeamColors: game.homeTeamColors,
                awayTeamColors: game.awayTeamColors
            )
        }
    }
    
    var featuredGame: Game? {
        games.max(by: { $0.totalBets < $1.totalBets })
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}
