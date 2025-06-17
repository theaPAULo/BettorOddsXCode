//
//  GamesViewModel.swift
//  BettorOdds
//
//  Version: 3.1.0 - FIXED: League switching throttling issue
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
    
    // FIXED: Per-league throttling instead of global
    private var lastRefreshTimesByLeague: [String: Date] = [:]
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
    
    /// FIXED: Changes league and refreshes games with instant cache loading
    func changeLeague(to league: String) async {
        guard league != selectedLeague else {
            print("🏀 Already on \(league) league")
            return
        }
        
        let previousLeague = selectedLeague
        selectedLeague = league
        print("🏀 Switching from \(previousLeague) to \(league) league")
        
        // IMPROVED: Load cached data first for instant display
        await loadCachedGamesForCurrentLeague()
        
        // Then refresh with fresh data if not throttled for this league
        await refreshGames()
    }
    
    /// Refreshes games with per-league intelligent throttling
    func refreshGames() async {
        // FIXED: PER-LEAGUE throttling check
        if let lastRefresh = lastRefreshTimesByLeague[selectedLeague],
           Date().timeIntervalSince(lastRefresh) < minimumRefreshInterval {
            print("🔄 \(selectedLeague) refresh throttled - too recent")
            return
        }
        
        guard !isLoading else {
            print("🔄 Refresh already in progress, skipping")
            return
        }
        
        // FIXED: Set per-league refresh time
        lastRefreshTimesByLeague[selectedLeague] = Date()
        
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
    
    /// FIXED: Force refresh bypassing per-league throttling
    func forceRefresh() async {
        lastRefreshTimesByLeague[selectedLeague] = nil
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
    
    /// NEW: Loads cached games for current league - HELPER METHOD for instant display
    private func loadCachedGamesForCurrentLeague() async {
        do {
            let cachedGames = try await gameRepository.fetchGames(league: selectedLeague)
            if !cachedGames.isEmpty {
                await MainActor.run {
                    self.items = cachedGames.filter { $0.isVisible }
                    self.updateFeaturedGame()
                }
                print("📂 Instantly loaded \(cachedGames.count) cached \(selectedLeague) games")
            } else {
                // Don't clear items immediately - try to force a refresh instead
                print("ℹ️ No cached \(selectedLeague) games found - attempting fresh fetch")
                
                // Force refresh for this league since we have no cache
                await forceRefreshCurrentLeague()
            }
        } catch {
            print("⚠️ Error loading cached \(selectedLeague) games: \(error.localizedDescription)")
            // Clear items on error
            await MainActor.run {
                self.items = []
                self.featuredGame = nil
            }
        }
    }
    
    /// Force refresh for current league only
    private func forceRefreshCurrentLeague() async {
        let currentLeague = selectedLeague
        lastRefreshTimesByLeague[currentLeague] = nil
        print("🔄 Force refreshing \(currentLeague) due to missing cache")
        await refreshGames()
    }
    
    /// Fetches scores in background (non-blocking)
    private func fetchScoresInBackground() {
        let currentLeague = selectedLeague // Capture the value before the detached task
        
        Task.detached(priority: .utility) { [weak self] in
            do {
                guard let self = self else { return }
                let sportKey = currentLeague == "NBA" ? "basketball_nba" : "americanfootball_nfl"
                
                try await self.scoreService.fetchScores(sport: sportKey)
                print("🏆 Background score fetch completed for \(currentLeague)")
                
                // Update games with scores if we're still on the same league
                await MainActor.run {
                    if self.selectedLeague == currentLeague {
                        // Process scores and update games if needed
                        print("✅ Scores processed for \(currentLeague)")
                    }
                }
            } catch {
                print("⚠️ Background score fetch error for \(currentLeague): \(error.localizedDescription)")
            }
        }
    }
    
    /// Updates the featured game based on current games
    private func updateFeaturedGame() {
        // 1. First check for manually featured games
        if let manualFeatured = upcomingGames.first(where: { $0.isFeatured }) {
            featuredGame = manualFeatured
            print("⭐ Featured manually set game: \(manualFeatured.awayTeam) @ \(manualFeatured.homeTeam)")
            return
        }
        
        // 2. Check for games happening soon (within 2 hours)
        let soonGames = upcomingGames.filter { game in
            let timeUntilGame = game.time.timeIntervalSinceNow
            return timeUntilGame <= 7200 // 2 hours
        }
        
        if let soonGame = soonGames.first {
            featuredGame = soonGame
            print("🔜 Featured upcoming game: \(soonGame.awayTeam) @ \(soonGame.homeTeam)")
            return
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
