//
//  AdminGameManagementView.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 1.0.0
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
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await db.collection("games")
                .order(by: "time", descending: false)
                .getDocuments()
            
            self.games = snapshot.documents.compactMap { document -> Game? in
                let data = document.data()
                // Map document data to Game properties
                // Add error handling here if needed
                return try? document.data(as: Game.self)
            }
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
    
    func setFeaturedGame(_ game: Game) async {
        do {
            // First, unset any currently featured game
            if let currentFeatured = games.first(where: { $0.isFeatured }) {
                try await db.collection("games").document(currentFeatured.id)
                    .updateData([
                        "isFeatured": false,
                        "lastUpdatedAt": Timestamp(date: Date()),
                        "lastUpdatedBy": Auth.auth().currentUser?.uid ?? "unknown"
                    ])
            }
            
            // Set the new featured game
            try await db.collection("games").document(game.id)
                .updateData([
                    "isFeatured": true,
                    "lastUpdatedAt": Timestamp(date: Date()),
                    "lastUpdatedBy": Auth.auth().currentUser?.uid ?? "unknown"
                ])
            
            await loadGames()
            self.successMessage = "Featured game updated successfully"
            self.showSuccess = true
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
    
    func toggleGameLock(_ game: Game) async {
        await updateGame(game, field: "isLocked", value: !game.isLocked)
    }
    
    func toggleGameVisibility(_ game: Game) async {
        await updateGame(game, field: "isVisible", value: !game.isVisible)
    }
    
    private func updateGame(_ game: Game, field: String, value: Any) async {
        do {
            try await db.collection("games").document(game.id)
                .updateData([
                    field: value,
                    "lastUpdatedAt": Timestamp(date: Date()),
                    "lastUpdatedBy": Auth.auth().currentUser?.uid ?? "unknown"
                ])
            
            await loadGames()
            self.successMessage = "Game updated successfully"
            self.showSuccess = true
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
}

struct AdminGameManagementView: View {
    @StateObject private var viewModel = AdminGameManagementViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            // Featured Game Section
            Section(header: Text("Featured Game").foregroundColor(.textSecondary)) {
                if let featuredGame = viewModel.games.first(where: { $0.isFeatured }) {
                    FeaturedGameRow(game: featuredGame)
                } else {
                    Text("No featured game selected")
                        .foregroundColor(.textSecondary)
                }
                
                Button("Select Featured Game") {
                    viewModel.showGameSelector = true
                }
                .foregroundColor(AppTheme.Brand.primary)
            }
            
            // Game Management Section
            Section(header: Text("Game Management").foregroundColor(.textSecondary)) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    ForEach(viewModel.games) { game in
                        GameManagementRow(
                            game: game,
                            onToggleLock: {
                                Task { await viewModel.toggleGameLock(game) }
                            },
                            onToggleVisibility: {
                                Task { await viewModel.toggleGameVisibility(game) }
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle("Game Management")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Done") { dismiss() })
        .sheet(isPresented: $viewModel.showGameSelector) {
            GameSelectorView(
                games: viewModel.availableGames,
                onSelect: { game in
                    Task {
                        await viewModel.setFeaturedGame(game)
                    }
                }
            )
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.successMessage ?? "Operation completed successfully")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .refreshable {
            await viewModel.loadGames()
        }
    }
}

// MARK: - Supporting Views

struct FeaturedGameRow: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(game.homeTeam) vs \(game.awayTeam)")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.textSecondary)
                Text(game.time.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            if let lastUpdated = game.lastUpdatedAt {
                Text("Last updated: \(lastUpdated.formatted())")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct GameManagementRow: View {
    let game: Game
    let onToggleLock: () -> Void
    let onToggleVisibility: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(game.homeTeam) vs \(game.awayTeam)")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack {
                // Locked Toggle
                HStack {
                    Text("Locked")
                        .foregroundColor(.textSecondary)
                    Button(action: onToggleLock) {
                        Image(systemName: game.isLocked ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(game.isLocked ? .red : .green)
                    }
                }
                
                Spacer()
                
                // Visible Toggle
                HStack {
                    Text("Visible")
                        .foregroundColor(.textSecondary)
                    Button(action: onToggleVisibility) {
                        Image(systemName: game.isVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(game.isVisible ? .green : .gray)
                    }
                }
            }
            
            if let lastUpdated = game.lastUpdatedAt {
                Text("Last updated: \(lastUpdated.formatted())")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct GameSelectorView: View {
    let games: [Game]
    let onSelect: (Game) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(games) { game in
                Button(action: {
                    onSelect(game)
                    dismiss()
                }) {
                    VStack(alignment: .leading) {
                        Text("\(game.homeTeam) vs \(game.awayTeam)")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text(game.time.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .navigationTitle("Select Featured Game")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

#Preview {
    NavigationView {
        AdminGameManagementView()
    }
}
