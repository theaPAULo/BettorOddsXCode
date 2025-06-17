//
//  GamesViewModel.swift
//  BettorOdds
//
//  Version: 3.0.1 - FINAL FIX for async/await issues and missing properties
//  Updated: June 2025
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class GamesViewModel: ListViewModel<Game> {
    
    // MARK: - Published Properties
    @Published private(set) var featuredGame: Game?
    @Published var balance: Double = 1000.0
    @Published var dailyBetsTotal: Double = 0.0
    @Published var selectedLeague: String = "NBA"
    
    // MARK: - Dependencies (Using Dependency Injection)
    @Inject private var gameRepository: GameRepository
    @Inject private var oddsService: OddsService
    @Inject private var scoreService: ScoreService
    
    // MARK: - Private Properties
    private let refreshInterval: TimeInterval = 300 // 5 minutes
    private var refreshTask: Task<Void, Never>?
    private var lastRefreshTime: Date?
    private let minimumRefreshInterval: TimeInterval = 60 // Prevent spam refreshing
    
    // MARK: - Computed Properties
    
    override var filteredItems: [Game] {
        return items
            .filter { $0.isVisible && $0.league == selectedLeague }
            .sorted { game1, game2 in
                // Featured games first, then by time
                if game1.isFeatured != game2.isFeatured {
                    return game1.isFeatured
                }
                return game1.time < game2.time
            }
    }
    
    var games: [Game] {
        return filteredItems
    }
    
    var upcomingGames: [Game] {
        return games.filter { $0.time > Date() && !$0.isLocked }
    }
    
    var liveGames: [Game] {
        return games.filter { $0.status == .inProgress }
    }

    // MARK: - Initialization
    
    override init() {
        super.init()
        print("🎮 GamesViewModel initialized with DI")
        setupAutoRefresh()
        
        Task {
            await loadInitialData()
        }
    }
    
    deinit {
        refreshTask?.cancel()
        print("🗑️ GamesViewModel deinitialized")
    }
    
    // MARK: - Public Methods
    
    override func loadItems() async {
        await refreshGames()
    }
    
    /// Changes league and refreshes games
    func changeLeague(to league: String) async {
        guard league != selectedLeague else {
            print("🏀 Already on \(league) league")
            return
        }
        
        selectedLeague = league
        print("🏀 Switching to \(league) league")
        
        // Clear current items to show loading state
        items = []
        featuredGame = nil
        
        await refreshGames()
    }
    
    /// Refreshes games with intelligent throttling
    func refreshGames() async {
        // Throttle refresh requests
        if let lastRefresh = lastRefreshTime,
           Date().timeIntervalSince(lastRefresh) < minimumRefreshInterval {
            print("🔄 Refresh throttled - too recent")
            return
        }
        
        guard !isLoading else {
            print("🔄 Refresh already in progress, skipping")
            return
        }
        
        lastRefreshTime = Date()
        
        await executeAsync({
            print("🔄 Starting games refresh for \(self.selectedLeague)")
            
            // 1. Try to load from cache first for instant UI update
            let cachedGames = try await self.gameRepository.fetchGames(league: self.selectedLeague)
            if !cachedGames.isEmpty {
                print("📂 Loaded \(cachedGames.count) cached games")
                await MainActor.run {
                    self.items = cachedGames.filter { $0.isVisible }
                    self.updateFeaturedGame()
                }
            }
            
            // 2. Fetch fresh games from API
            let freshGames = try await self.oddsService.fetchGames(for: self.selectedLeague)
            print("📊 Fetched \(freshGames.count) fresh \(self.selectedLeague) games")
            
            // 3. Sync to Firebase (non-blocking)
            Task.detached(priority: .background) {
                do {
                    try await self.gameRepository.syncGames(freshGames)
                    print("✅ Games synced to Firebase")
                } catch {
                    print("⚠️ Failed to sync games: \(error.localizedDescription)")
                }
            }
            
            // 4. Fetch scores in background (non-critical)
            self.fetchScoresInBackground()
            
            // 5. Return the fresh games
            return freshGames.filter { $0.isVisible }
            
        }, onSuccess: { [weak self] (loadedGames: [Game]) in
            self?.items = loadedGames
            self?.updateFeaturedGame()
            print("✅ Games refresh completed with \(loadedGames.count) games")
            
        }, onError: { [weak self] error in
            print("❌ Games refresh error: \(error.localizedDescription)")
            // If we have cached games, keep showing them
            if self?.items.isEmpty == true {
                Task { [weak self] in
                    await self?.loadCachedGames()
                }
            }
        })
    }
    
    override func refresh() async {
        await refreshGames()
    }
    
    /// Force refresh bypassing throttling
    func forceRefresh() async {
        lastRefreshTime = nil
        await refreshGames()
    }
    
    // MARK: - Private Methods
    
    /// Loads initial data with smart caching strategy
    private func loadInitialData() async {
        // First load cached data for instant UI
        await loadCachedGames()
        
        // Then refresh with fresh data
        await refreshGames()
    }
    
    /// Loads cached games from repository
    private func loadCachedGames() async {
        do {
            let cachedGames = try await gameRepository.fetchGames(league: selectedLeague)
            if !cachedGames.isEmpty {
                await MainActor.run {
                    self.items = cachedGames.filter { $0.isVisible }
                    self.updateFeaturedGame()
                }
                print("📂 Loaded \(cachedGames.count) cached games")
            } else {
                print("ℹ️ No cached games found for \(selectedLeague)")
            }
        } catch {
            print("❌ Error loading cached games: \(error.localizedDescription)")
        }
    }
    
    /// Fetches scores in background (non-blocking)
    private func fetchScoresInBackground() {
        let currentLeague = selectedLeague // Capture the value before the detached task
        
        Task.detached(priority: .utility) { [weak self] in
            do {
                guard let self = self else { return }
                let sportKey = currentLeague == "NBA" ? "basketball_nba" : "americanfootball_nfl"
                try await self.scoreService.fetchScores(sport: sportKey)
                print("✅ Score fetching completed for \(currentLeague)")
            } catch {
                // Non-critical error - don't propagate
                print("⚠️ Score fetching failed (non-critical): \(error.localizedDescription)")
            }
        }
    }
    
    /// Updates the featured game based on business logic
    private func updateFeaturedGame() {
        print("🔍 Looking for featured game in \(selectedLeague)...")
        
        // 1. Check for manually featured games first
        if let manuallyFeatured = items.first(where: { $0.isFeatured && $0.league == selectedLeague }) {
            featuredGame = manuallyFeatured
            print("✨ Found manually featured game: \(manuallyFeatured.awayTeam) @ \(manuallyFeatured.homeTeam)")
            return
        }
        
        // 2. Find upcoming games that can be bet on
        let upcomingGames = items.filter {
            $0.league == selectedLeague &&
            $0.time > Date() &&
            $0.isVisible &&
            !$0.isLocked
        }
        
        // 3. Pick the most popular upcoming game
        if let popularGame = upcomingGames.max(by: { $0.totalBets < $1.totalBets }) {
            featuredGame = popularGame
            print("📊 Featured most popular game: \(popularGame.awayTeam) @ \(popularGame.homeTeam) (\(popularGame.totalBets) bets)")
        } else if let nextGame = upcomingGames.first {
            // 4. Fallback to next chronological game
            featuredGame = nextGame
            print("⏰ Featured next game: \(nextGame.awayTeam) @ \(nextGame.homeTeam)")
        } else {
            featuredGame = nil
            print("❌ No featured game found for \(selectedLeague)")
        }
    }
    
    /// Sets up automatic refresh timer
    private func setupAutoRefresh() {
        refreshTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(refreshInterval))
                    if !Task.isCancelled {
                        await refreshGames()
                    }
                } catch {
                    // Task was cancelled or sleep failed
                    break
                }
            }
        }
        print("⏰ Auto-refresh timer started (every \(refreshInterval)s)")
    }
    
    // MARK: - Admin Helper Methods - FIXED ASYNC/AWAIT
    
    /// Helper for admin to force refresh all leagues
    func adminRefreshAllLeagues() async {
        let leagues = ["NBA", "NFL", "MLB", "NHL"]
        let originalLeague = selectedLeague
        
        for league in leagues {
            await changeLeague(to: league)
            await forceRefresh()
        }
        
        // Return to original league
        await changeLeague(to: originalLeague)
    }
    
    /// Get detailed game statistics for admin
    func getGameStatistics() -> (total: Int, visible: Int, locked: Int, featured: Int) {
        let allGames = items
        return (
            total: allGames.count,
            visible: allGames.filter { $0.isVisible }.count,
            locked: allGames.filter { $0.isLocked }.count,
            featured: allGames.filter { $0.isFeatured }.count
        )
    }
}

// MARK: - Extensions for Better Organization

extension GamesViewModel {
    /// Checks if we should show loading state
    var shouldShowLoading: Bool {
        return isLoading && items.isEmpty
    }
    
    /// Checks if we should show empty state
    var shouldShowEmptyState: Bool {
        return !isLoading && items.isEmpty
    }
    
    /// Gets display text for current state
    var stateDisplayText: String {
        if shouldShowLoading {
            return "Loading \(selectedLeague) games..."
        } else if shouldShowEmptyState {
            return "No \(selectedLeague) games available"
        } else {
            return "\(games.count) \(selectedLeague) games"
        }
    }
}
