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
    
    // MARK: - Private Properties
    private let refreshInterval: TimeInterval = 300 // 5 minutes
    private var refreshTask: Task<Void, Never>?
    private let gameRepository = GameRepository()
    
    // User balance info (would come from UserService in production)
    @Published var balance: Double = 1000.0
    @Published var dailyBetsTotal: Double = 0.0
    
    private let oddsService = OddsService.shared

    // MARK: - Initialization
    init() {
        setupRefreshTimer()
    }
    
    // MARK: - Public Methods
    
    /// Refreshes games data from The Odds API and syncs to Firebase
    // Update your refreshGames() method in GamesViewModel.swift with this version:

    func refreshGames() async {
        guard !isLoading else { return }  // Prevent multiple simultaneous refreshes
        
        isLoading = true
        error = nil
        
        do {
            print("🔄 Starting games refresh from The Odds API")
            
            // 1. Fetch fresh games from The Odds API
            let freshGames = try await oddsService.fetchGames()
            print("📊 Fetched \(freshGames.count) games from The Odds API")
            
            // 2. Sync games to Firebase
            print("💾 Syncing games to Firebase")
            try await gameRepository.syncGames(freshGames)
            
            // 3. Fetch scores for completed games (with improved error handling)
            print("🎯 Fetching scores from The Odds API")
            do {
                let scoreService = ScoreService.shared
                try await scoreService.fetchScores(sport: "basketball_nba")
                print("✅ Score fetching completed successfully")
            } catch {
                print("⚠️ Score fetching failed (non-critical): \(error.localizedDescription)")
                // Don't let score fetching errors stop the entire game loading process
                print("ℹ️ Continuing with game loading despite score issues")
            }
            
            // 4. Fetch games from Firebase (includes admin settings like featured status and scores)
            let snapshot = try await FirebaseConfig.shared.db.collection("games")
                .order(by: "time", descending: false)
                .getDocuments()
            
            print("📚 Got \(snapshot.documents.count) total games from Firebase")
            
            var loadedGames: [Game] = []
            for document in snapshot.documents {
                if let game = Game(from: document) {
                    print("""
                        🎮 Processing game from Firebase:
                        - ID: \(game.id)
                        - Teams: \(game.homeTeam) vs \(game.awayTeam)
                        - Time: \(game.time)
                        - League: \(game.league)
                        - isVisible: \(game.isVisible)
                        - isLocked: \(game.isLocked)
                        - shouldBeLocked: \(game.shouldBeLocked)
                        - hasScore: \(game.score != nil)
                        """)
                    
                    // Check for score if game might be completed
                    var gameToAdd = game
                    
                    // Only try to load scores for games that have started
                    if game.time <= Date() {
                        do {
                            if let score = try await gameRepository.getScore(for: game.id) {
                                var updatedGame = game
                                updatedGame.score = score
                                
                                // Update game document with score and preserve spread
                                try? await FirebaseConfig.shared.db.collection("games").document(game.id).updateData([
                                    "score": score.toDictionary(),
                                    "spread": game.isLocked ? game.spread : updatedGame.spread,
                                    "isLocked": true
                                ])
                                
                                gameToAdd = updatedGame
                                print("✅ Found score for \(game.homeTeam) vs \(game.awayTeam): \(score.homeScore)-\(score.awayScore)")
                            }
                        } catch {
                            print("⚠️ Could not load score for game \(game.id): \(error.localizedDescription)")
                            // Continue with game without score
                        }
                    }
                    
                    // Only add visible games
                    if gameToAdd.isVisible {
                        loadedGames.append(gameToAdd)
                        print("✅ Added visible game: \(game.id)")
                    } else {
                        print("⚠️ Skipping invisible game: \(game.id)")
                    }
                } else {
                    print("❌ Failed to parse game from document: \(document.documentID)")
                }
            }
            
            // 5. Update games and find featured game
            await MainActor.run {
                self.games = loadedGames
                print("📱 Updated games array with \(loadedGames.count) games")
                
                // Find featured game
                if let featured = loadedGames.first(where: { $0.manuallyFeatured }) {
                    print("⭐️ Setting featured game: \(featured.id)")
                    self.featuredGame = featured
                } else {
                    print("❌ No featured game found")
                    self.featuredGame = nil
                }
            }
            
        } catch {
            print("❌ Error refreshing games: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
        private func updateFeaturedGame() {
            print("🔍 Looking for featured game...")
            if let manuallyFeatured = games.first(where: { $0.manuallyFeatured }) {
                print("⭐️ Found manually featured game: \(manuallyFeatured.id)")
                featuredGame = manuallyFeatured
                return
            }
            
            print("📊 No manually featured game, selecting by bet count")
            featuredGame = games
                .filter { !$0.shouldBeLocked && !$0.isLocked }
                .max(by: { $0.totalBets < $1.totalBets })
            
            if let selected = featuredGame {
                print("✨ Selected featured game: \(selected.id)")
            } else {
                print("❌ No featured game selected")
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
