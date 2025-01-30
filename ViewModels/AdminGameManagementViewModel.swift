//
//  AdminGameManagementViewModel.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 1.1.0
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AdminGameManagementViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var selectedGame: Game?
    @Published var isLoading = false
    @Published var showError = false
    @Published var showSuccess = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showGameSelector = false
    
    private let db = Firestore.firestore()
    
    // Filtered games for the selector
    var availableGames: [Game] {
        games.filter { !$0.isFeatured }
    }
    
    init() {
        Task {
            await loadGames()
        }
    }
    
    func loadGames() async {
        await MainActor.run {
            isLoading = true
            print("🎮 Starting to load games...")
        }
        
        do {
            let snapshot = try await db.collection("games")
                .order(by: "time", descending: false)
                .getDocuments()
            
            print("📚 Got \(snapshot.documents.count) games from Firestore")
            
            let loadedGames = snapshot.documents.compactMap { document -> Game? in
                do {
                    let game = try document.data(as: Game.self)
                    print("✅ Successfully parsed game: \(game.id)")
                    return game
                } catch {
                    print("❌ Failed to parse game document: \(error)")
                    return nil
                }
            }
            
            await MainActor.run {
                self.games = loadedGames
                self.isLoading = false
                print("🎯 Loaded \(loadedGames.count) games successfully")
            }
        } catch {
            print("❌ Error loading games: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load games: \(error.localizedDescription)"
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    func setFeaturedGame(_ game: Game) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // First, unset any currently featured game
            if let currentFeatured = games.first(where: { $0.isFeatured }) {
                print("🔄 Unsetting current featured game: \(currentFeatured.id)")
                try await db.collection("games").document(currentFeatured.id)
                    .updateData([
                        "isFeatured": false,
                        "lastUpdatedAt": Timestamp(date: Date()),
                        "lastUpdatedBy": Auth.auth().currentUser?.uid ?? "unknown"
                    ])
            }
            
            print("⭐️ Setting new featured game: \(game.id)")
            // Set the new featured game
            try await db.collection("games").document(game.id)
                .updateData([
                    "isFeatured": true,
                    "lastUpdatedAt": Timestamp(date: Date()),
                    "lastUpdatedBy": Auth.auth().currentUser?.uid ?? "unknown"
                ])
            
            await loadGames()
            
            await MainActor.run {
                self.successMessage = "Featured game updated successfully"
                self.showSuccess = true
                self.isLoading = false
            }
            
        } catch {
            print("❌ Error setting featured game: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    func toggleGameLock(_ game: Game) async {
        await updateGame(game, field: "isLocked", value: !game.isLocked)
    }
    
    func toggleGameVisibility(_ game: Game) async {
        await updateGame(game, field: "isVisible", value: !game.isVisible)
    }
    
    private func updateGame(_ game: Game, field: String, value: Any) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            print("🔄 Updating game \(game.id) - Setting \(field) to \(value)")
            try await db.collection("games").document(game.id)
                .updateData([
                    field: value,
                    "lastUpdatedAt": Timestamp(date: Date()),
                    "lastUpdatedBy": Auth.auth().currentUser?.uid ?? "unknown"
                ])
            
            await loadGames()
            
            await MainActor.run {
                self.successMessage = "Game updated successfully"
                self.showSuccess = true
                self.isLoading = false
            }
            
        } catch {
            print("❌ Error updating game: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
        }
    }
}
