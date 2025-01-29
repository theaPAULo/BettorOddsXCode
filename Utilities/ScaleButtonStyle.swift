//
//  ScaleButtonStyle.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/29/25.
//


import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}