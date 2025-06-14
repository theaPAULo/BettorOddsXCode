//
//  AdminGameManagementView.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 1.1.0 - Updated for EnhancedTheme compatibility
//

import SwiftUI

struct AdminGameManagementView: View {
    @StateObject private var viewModel = AdminGameManagementViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            // Featured Game Section
            Section {
                if let featuredGame = viewModel.games.first(where: { $0.isFeatured }) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("\(featuredGame.homeTeam) vs \(featuredGame.awayTeam)")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(featuredGame.time.formatted(date: .abbreviated, time: .shortened))
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                } else {
                    Text("No featured game selected")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Button("Select Featured Game") {
                    viewModel.showGameSelector = true
                }
                .foregroundColor(Color.primary)
            } header: {
                Text("Featured Game")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            } footer: {
                Text("Featured games appear at the top of the list.")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // All Games Section
            Section {
                ForEach(viewModel.games) { game in
                    GameManagementRow(
                        game: game,
                        onToggleLock: {
                            Task {
                                await viewModel.toggleGameLock(game)
                            }
                        },
                        onToggleVisibility: {
                            Task {
                                await viewModel.toggleGameVisibility(game)
                            }
                        }
                    )
                }
            } header: {
                Text("All Games")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .navigationTitle("Game Management")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh") {
                    Task {
                        await viewModel.loadGames()
                    }
                }
                .foregroundColor(Color.primary)
            }
        }
        .sheet(isPresented: $viewModel.showGameSelector) {
            GameSelectorView(games: viewModel.games) { game in
                Task {
                    await viewModel.setFeaturedGame(game)
                }
            }
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("\(game.homeTeam) vs \(game.awayTeam)")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text(game.time.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            if let lastUpdated = game.lastUpdatedAt {
                Text("Last updated: \(lastUpdated.formatted())")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

struct GameManagementRow: View {
    let game: Game
    let onToggleLock: () -> Void
    let onToggleVisibility: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("\(game.homeTeam) vs \(game.awayTeam)")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            HStack {
                // Locked Toggle
                HStack {
                    Text("Locked")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Button(action: onToggleLock) {
                        Image(systemName: game.isLocked ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(game.isLocked ? AppTheme.Colors.error : AppTheme.Colors.success)
                    }
                }
                
                Spacer()
                
                // Visible Toggle
                HStack {
                    Text("Visible")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Button(action: onToggleVisibility) {
                        Image(systemName: game.isVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(game.isVisible ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                    }
                }
            }
            
            if let lastUpdated = game.lastUpdatedAt {
                Text("Last updated: \(lastUpdated.formatted())")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
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
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(game.time.formatted(date: .abbreviated, time: .shortened))
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Select Featured Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        AdminGameManagementView()
    }
}
