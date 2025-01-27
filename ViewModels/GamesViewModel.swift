//
//  GamesViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.0.0
//

import SwiftUI

@MainActor
class GamesViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var games: [Game] = []
    @Published private(set) var featuredGame: Game?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    // User balance info (would come from UserService in production)
    @Published var balance: Double = 1000.0
    @Published var dailyBetsTotal: Double = 0.0
    
    // MARK: - Private Properties
    private let refreshInterval: TimeInterval = 300 // 5 minutes
    private var refreshTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init() {
        setupRefreshTimer()
    }
    
    // MARK: - Public Methods
    func refreshGames() async {
        isLoading = true
        error = nil
        
        do {
            print("🔄 Fetching games...")
            games = try await OddsService.shared.fetchGames()
            print("✅ Fetched \(games.count) games")
            updateFeaturedGame()
            
            if games.isEmpty {
                print("⚠️ No games were fetched")
            }
            
        } catch {
            print("❌ Error fetching games: \(error)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    private func setupRefreshTimer() {
        // Cancel any existing refresh task
        refreshTask?.cancel()
        
        // Create new refresh task
        refreshTask = Task {
            while !Task.isCancelled {
                await refreshGames()
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
            }
        }
    }
    
    private func updateFeaturedGame() {
        // Select game with highest total bets as featured
        featuredGame = games.max(by: { $0.totalBets < $1.totalBets })
    }
    
    // MARK: - Cleanup
    deinit {
        refreshTask?.cancel()
    }
}
