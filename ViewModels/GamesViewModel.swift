//
//  GamesViewModel.swift
//  BettorOdds
//
//  Version: 2.6.0 - Final fix for line 82 and league support
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
    
    // MARK: - Private Properties
    private let refreshInterval: TimeInterval = 300 // 5 minutes
    private var refreshTask: Task<Void, Never>?
    private let gameRepository = GameRepository()
    private let oddsService = OddsService.shared
    private let scoreService = ScoreService.shared
    
    // MARK: - Computed Properties
    
    override var filteredItems: [Game] {
        return items
            .filter { $0.isVisible && $0.league == selectedLeague }
            .sorted { game1, game2 in
                if game1.isFeatured != game2.isFeatured {
                    return game1.isFeatured
                }
                return game1.time < game2.time
            }
    }
    
    var games: [Game] {
        return filteredItems
    }

    // MARK: - Initialization
    
    override init() {
        super.init()
        setupRefreshTimer()
        
        Task {
            await loadCachedGames()
        }
    }
    
    // MARK: - Public Methods
    
    override func loadItems() async {
        await refreshGames()
    }
    
    func changeLeague(to league: String) async {
        selectedLeague = league
        print("🏀 Switching to \(league) league")
        await refreshGames()
    }
    
    func refreshGames() async {
        guard !isLoading else {
            print("🔄 Refresh already in progress, skipping")
            return
        }
        
        executeAsync({
            print("🔄 Starting games refresh for \(self.selectedLeague)")
            
            // 1. Fetch fresh games
            let freshGames = try await self.oddsService.fetchGames(for: self.selectedLeague)
            print("📊 Fetched \(freshGames.count) \(self.selectedLeague) games")
            
            // 2. Sync to Firebase
            try await self.gameRepository.syncGames(freshGames)
            
            // 3. Fetch scores (non-critical) - FIXED: Remove await here
            self.fetchScoresInBackground()
            
            // 4. Load updated games
            let loadedGames = try await self.gameRepository.fetchGames(league: self.selectedLeague)
            print("📚 Loaded \(loadedGames.count) games from Firebase")
            
            return loadedGames
            
        }, onSuccess: { [weak self] (loadedGames: [Game]) in
            self?.items = loadedGames.filter { $0.isVisible }
            self?.updateFeaturedGame()
            print("✅ Games refresh completed")
            
        }, onError: { [weak self] error in
            print("❌ Games refresh error: \(error.localizedDescription)")
            Task { [weak self] in
                await self?.loadCachedGames()
            }
        })
    }
    
    override func refresh() async {
        await refreshGames()
    }
    
    // MARK: - Private Methods
    
    private func loadCachedGames() async {
        do {
            let cachedGames = try await gameRepository.fetchGames(league: selectedLeague)
            if !cachedGames.isEmpty {
                items = cachedGames.filter { $0.isVisible }
                updateFeaturedGame()
                print("📂 Loaded \(cachedGames.count) cached games")
            } else {
                print("ℹ️ No cached games found")
            }
        } catch {
            print("❌ Error loading cached games: \(error)")
        }
    }
    
    private func fetchScoresInBackground() {
        Task { [weak self] in
            do {
                guard let self = self else { return }
                let sportKey = self.selectedLeague == "NBA" ? "basketball_nba" : "americanfootball_nfl"
                try await self.scoreService.fetchScores(sport: sportKey)
                print("✅ Score fetching completed for \(self.selectedLeague)")
            } catch {
                print("⚠️ Score fetching failed (non-critical): \(error.localizedDescription)")
            }
        }
    }
    
    private func updateFeaturedGame() {
        print("🔍 Looking for featured game in \(selectedLeague)...")
        
        if let manuallyFeatured = items.first(where: { $0.isFeatured && $0.league == selectedLeague }) {
            featuredGame = manuallyFeatured
            print("✨ Found manually featured game: \(manuallyFeatured.awayTeam) @ \(manuallyFeatured.homeTeam)")
            return
        }
        
        let upcomingGames = items.filter {
            $0.league == selectedLeague &&
            $0.time > Date() &&
            $0.isVisible &&
            !$0.isLocked
        }
        
        if let popularGame = upcomingGames.max(by: { $0.totalBets < $1.totalBets }) {
            featuredGame = popularGame
            print("📊 Found popular game: \(popularGame.awayTeam) @ \(popularGame.homeTeam)")
        } else {
            featuredGame = upcomingGames.first
            if let fallback = featuredGame {
                print("⏰ Using next game: \(fallback.awayTeam) @ \(fallback.homeTeam)")
            } else {
                print("❌ No featured game found")
            }
        }
    }
    
    private func setupRefreshTimer() {
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(refreshInterval))
                if !Task.isCancelled {
                    await refreshGames()
                }
            }
        }
    }
    
    deinit {
        refreshTask?.cancel()
    }
}
