//
//  CustomButton.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//  Version: 2.2.0 - Fixed typography reference
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
                return Color.primary
            case .secondary:
                return Color.secondary
            case .outline:
                return .clear
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .secondary:
                return AppTheme.Colors.textPrimary
            case .outline:
                return Color.primary
            }
        }
        
        var borderColor: Color {
            switch self {
            case .outline:
                return Color.primary
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
                        .font(AppTheme.Typography.bodyBold) // Fixed: using bodyBold instead of button
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundColor(style.textColor)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(
                        disabled ? Color.gray.opacity(0.5) : style.backgroundColor
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(
                        style.borderColor.opacity(disabled ? 0.3 : 1.0),
                        lineWidth: style == .outline ? 2 : 1
                    )
            )
            .shadow(
                color: disabled ? .clear : AppTheme.Shadow.medium.color,
                radius: AppTheme.Shadow.medium.radius,
                x: AppTheme.Shadow.medium.x,
                y: AppTheme.Shadow.medium.y
            )
            .opacity(disabled ? 0.6 : 1.0)
        }
        .disabled(isLoading || disabled)
    }
}

#Preview {
    VStack(spacing: AppTheme.Spacing.lg) {
        CustomButton(title: "Primary Button", action: {})
        CustomButton(title: "Secondary Button", action: {}, style: .secondary)
        CustomButton(title: "Outline Button", action: {}, style: .outline)
        CustomButton(title: "Loading Button", action: {}, isLoading: true)
        CustomButton(title: "Disabled Button", action: {}, disabled: true)
    }
    .padding(AppTheme.Spacing.lg)
    .background(AppTheme.Colors.background)
}
