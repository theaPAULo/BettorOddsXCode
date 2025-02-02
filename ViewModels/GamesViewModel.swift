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

    // MARK: - Initialization
    init() {
        setupRefreshTimer()
    }
    
    // MARK: - Public Methods
    
    /// Refreshes games data from Firestore
    func refreshGames() async {
        isLoading = true
        error = nil
        
        do {
            print("🔄 Starting games refresh")
            
            // Use FirebaseConfig.shared.db instead of direct db access
            let snapshot = try await FirebaseConfig.shared.db.collection("games")
                .order(by: "time", descending: false)
                .getDocuments()
            
            print("📚 Got \(snapshot.documents.count) total games")
            
            var loadedGames: [Game] = []
            for document in snapshot.documents {
                if let game = Game(from: document) {
                    // Only add visible games
                    if game.isVisible {
                        loadedGames.append(game)
                        print("✅ Added visible game: \(game.id)")
                    } else {
                        print("⚠️ Skipped invisible game: \(game.id)")
                    }
                }
            }
            
            await MainActor.run {
                self.games = loadedGames
                self.updateFeaturedGame()
                print("🎯 Updated games list with \(loadedGames.count) visible games")
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
