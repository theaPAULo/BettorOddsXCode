//
//  AnimatedBackground.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.1.0 - Updated with local hex support (preserves readability)
//

import SwiftUI

struct AnimatedBackground: View {
    // MARK: - Properties
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateGradient = false
    
    // MARK: - Color Sets
    private var colors: [Color] {
        colorScheme == .dark ? darkModeColors : lightModeColors
    }
    
    // Now we can use readable hex values!
    private let lightModeColors = [
        TeamColors.colorFromHex("f8f9fa").opacity(0.8),
        TeamColors.colorFromHex("e9ecef").opacity(0.8),
        TeamColors.colorFromHex("dee2e6").opacity(0.8)
    ]
    
    private let darkModeColors = [
        TeamColors.colorFromHex("212529").opacity(0.8),
        TeamColors.colorFromHex("343a40").opacity(0.8),
        TeamColors.colorFromHex("495057").opacity(0.8)
    ]
    
    // MARK: - Body
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .linear(duration: 5.0)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient.toggle()
            }
        }
    }
}

#Preview {
    VStack {
        Text("Sample Content")
            .font(.title)
            .foregroundColor(.primary)
    }
    .background(AnimatedBackground())
}
