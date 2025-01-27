//
//  GamesView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//

import SwiftUI

struct GamesView: View {
    @StateObject private var viewModel = GamesViewModel()
    @State private var selectedGame: Game?
    @State private var showBetModal = false
    @State private var selectedLeague = "NBA"  // Default to NBA
    
    let leagues = ["NBA", "NFL"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Balance Header
            HStack {
                Text("BettorOdds")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color("Primary"))
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$ \(Int(viewModel.balance))")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("Daily Total: $\(Int(viewModel.dailyBetsTotal))/100")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
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
            
            // Games List
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
            .refreshable {
                await viewModel.refreshGames()
            }
        }
        .sheet(isPresented: $showBetModal) {
            if let game = selectedGame {
                BetModal(game: game, isPresented: $showBetModal)
            }
        }
    }
}

#Preview {
    GamesView()
}
