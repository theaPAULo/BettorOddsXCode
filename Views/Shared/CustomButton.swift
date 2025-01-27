//
//  CustomButton.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//  Version: 2.0.0
//

import SwiftUI

struct CustomButton: View {
    let title: String
    let action: () -> Void
    var style: ButtonStyle = .primary
    var isLoading: Bool = false
    var disabled: Bool = false
    
    enum ButtonStyle {
        case primary
        case secondary
        case outline
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return AppTheme.Brand.primary
            case .secondary:
                return AppTheme.Brand.secondary
            case .outline:
                return .clear
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .secondary:
                return AppTheme.Text.primary
            case .outline:
                return AppTheme.Brand.primary
            }
        }
        
        var borderColor: Color {
            switch self {
            case .outline:
                return AppTheme.Brand.primary
            default:
                return .clear
            }
        }
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && !disabled {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                action()
            }
        }) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.textColor))
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundColor(style.textColor)
            .background(style.backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.borderColor, lineWidth: style == .outline ? 2 : 0)
            )
            .opacity(disabled ? 0.6 : 1.0)
        }
        .disabled(isLoading || disabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomButton(title: "Primary Button", action: {})
        CustomButton(title: "Secondary Button", action: {}, style: .secondary)
        CustomButton(title: "Outline Button", action: {}, style: .outline)
        CustomButton(title: "Loading Button", action: {}, isLoading: true)
        CustomButton(title: "Disabled Button", action: {}, disabled: true)
    }
    .padding()
}
