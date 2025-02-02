//
//  GamesViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.1.0
//

import SwiftUI
import FirebaseFirestore

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
    private let gameRepository = GameRepository()
    
    // MARK: - Initialization
    init() {
        setupRefreshTimer()
    }
    
    // MARK: - Public Methods
    
    /// Refreshes games data from The Odds API and syncs to Firestore
    func refreshGames() async {
        isLoading = true
        error = nil
        
        do {
            print("🔄 Fetching games from The Odds API...")
            games = try await OddsService.shared.fetchGames()
            print("✅ Fetched \(games.count) games from API")
            
            // Sync games to Firestore
            do {
                print("🔄 Starting Firestore sync...")
                try await gameRepository.syncGames(games)
                print("✅ Successfully synced games to Firestore")
            } catch {
                print("⚠️ Failed to sync games to Firestore: \(error.localizedDescription)")
                // Don't fail the entire refresh if sync fails
            }
            
            updateFeaturedGame()
            
            if games.isEmpty {
                print("⚠️ No games were fetched")
            }
            
        } catch {
            print("❌ Error fetching games: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }

    // MARK: - Private Methods
    
    /// Updates the featured game selection
    private func updateFeaturedGame() {
        // First check for manually featured game
        if let manuallyFeatured = games.first(where: { $0.manuallyFeatured }) {
            print("📌 Using manually featured game: \(manuallyFeatured.id)")
            featuredGame = manuallyFeatured
            return
        }
        
        // Otherwise, select game with highest bet count that isn't locked
        print("🔍 Selecting featured game based on bet count...")
        featuredGame = games
            .filter { !$0.shouldBeLocked }
            .max(by: { $0.totalBets < $1.totalBets })
        
        if let selected = featuredGame {
            print("✅ Selected featured game: \(selected.id) with \(selected.totalBets) bets")
        } else {
            print("⚠️ No featured game selected")
        }
    }
    
    /// Sets up automatic refresh timer
    private func setupRefreshTimer() {
        print("⏰ Setting up refresh timer with interval: \(refreshInterval) seconds")
        
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
    
    // MARK: - Cleanup
    deinit {
        print("🧹 Cleaning up GamesViewModel")
        refreshTask?.cancel()
    }
}
