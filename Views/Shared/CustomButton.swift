//
//  CustomButton.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//


// File: Views/Shared/CustomButton.swift
// Version: 1.0
// Description: Reusable button component with different styles

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
                return AppTheme.primary
            case .secondary:
                return AppTheme.secondary
            case .outline:
                return .clear
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .secondary:
                return .white
            case .outline:
                return AppTheme.primary
            }
        }
        
        var borderColor: Color {
            switch self {
            case .outline:
                return AppTheme.primary
            default:
                return .clear
            }
        }
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && !disabled {
                // Add haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                action()
            }
        }) {
            ZStack {
                // Button content
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.textColor))
                } else {
                    Text(title)
                        .font(.system(size: AppTheme.ButtonStyle.fontSize, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.ButtonStyle.height)
            .foregroundColor(style.textColor)
            .background(style.backgroundColor)
            .cornerRadius(AppTheme.ButtonStyle.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.ButtonStyle.cornerRadius)
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