//
//  BetModal.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//

import SwiftUI

struct BetModal: View {
    let game: Game
    @Binding var isPresented: Bool
    
    var body: some View {
        Text("Bet Modal - Coming Soon")
            .onTapGesture {
                isPresented = false
            }
    }
}

#Preview {
    BetModal(
        game: Game.sampleGames[0],
        isPresented: .constant(true)
    )
}
