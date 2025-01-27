//
//  GamesView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.1.0
//

import SwiftUI

struct GamesView: View {
    // MARK: - Properties
    @StateObject private var viewModel = GamesViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedGame: Game?
    @State private var showBetModal = false
    @State private var selectedLeague = "NBA"
    
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
            
            // Games List or Loading State
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.top, 40)
            } else if let error = viewModel.error {
                VStack(spacing: 16) {
                    Text("⚠️ Error loading games")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task {
                            await viewModel.refreshGames()
                        }
                    }
                    .padding()
                    .background(Color("Primary"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            } else if viewModel.games.isEmpty {
                VStack(spacing: 16) {
                    Text("No games available")
                        .font(.headline)
                    Text("Pull down to refresh")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.games.filter { $0.league == selectedLeague }) { game in
                            GameCard(
                                game: game,
                                isFeatured: game.id == viewModel.featuredGame?.id
                            ) {
                                selectedGame = game
                                showBetModal = true
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshGames()
            }
        }
        .refreshable {
            await viewModel.refreshGames()
        }
        .sheet(isPresented: $showBetModal) {
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
