//
//  GamesView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 2.1.0

import SwiftUI

struct GamesView: View {
    // MARK: - Properties
    @StateObject private var viewModel = GamesViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedGame: Game?
    @State private var showBetModal = false
    @State private var selectedLeague = "NBA"
    @State private var globalSelectedTeam: (gameId: String, team: TeamSelection)?
    
    let leagues = ["NBA", "NFL"]
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Balance Header
            BalanceHeader(
                yellowCoins: authViewModel.user?.yellowCoins ?? 0,
                greenCoins: authViewModel.user?.greenCoins ?? 0,
                dailyGreenCoinsUsed: authViewModel.user?.dailyGreenCoinsUsed ?? 0
            )
            
            // League Selector
            HStack(spacing: 20) {
                ForEach(leagues, id: \.self) { league in
                    Button(action: {
                        withAnimation {
                            selectedLeague = league
                            // Clear selection when changing leagues
                            globalSelectedTeam = nil
                        }
                    }) {
                        Text(league)
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedLeague == league ? Color("Primary") : Color.clear)
                            )
                            .foregroundColor(selectedLeague == league ? .white : .gray)
                    }
                }
            }
            .padding(.vertical, 8)
            
            // Games List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.games.filter { $0.league == selectedLeague }) { game in
                        GameCard(
                            game: game,
                            isFeatured: game.id == viewModel.featuredGame?.id,
                            onSelect: {
                                selectedGame = game
                                showBetModal = true
                            },
                            globalSelectedTeam: $globalSelectedTeam
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .refreshable {
                await viewModel.refreshGames()
            }
        }
        .sheet(isPresented: $showBetModal) {
            // Clear selection when modal is dismissed
            globalSelectedTeam = nil
        } content: {
            if let game = selectedGame,
               let user = authViewModel.user {
                BetModal(
                    game: game,
                    user: user,
                    isPresented: $showBetModal
                )
            }
        }
    }
}
