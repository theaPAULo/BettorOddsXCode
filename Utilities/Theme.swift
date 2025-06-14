//
//  AppTheme.swift
//  BettorOdds
//
//  Version: 2.0.0 - Enhanced gradients and modern design system
//  Updated: June 2025

import SwiftUI

struct AppTheme {
    
    // MARK: - Colors
    
    struct Colors {
        // MARK: - Primary Brand Colors
        static let primary = Color.primary // Use existing extension
        static let primaryDark = Color(red: 0.0, green: 0.72, blue: 0.64)
        static let secondary = Color(red: 0.30, green: 0.80, blue: 0.77)
        static let accent = Color(red: 1.0, green: 0.90, blue: 0.43)
        
        // MARK: - Enhanced Background Gradients
        
        // Main app background - sophisticated teal gradient
        static let background = LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.13, blue: 0.15), // Deep navy
                Color(red: 0.13, green: 0.23, blue: 0.26), // Teal-gray
                Color(red: 0.17, green: 0.33, blue: 0.39)  // Lighter teal-gray
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Alternative background for variety
        static let backgroundAlt = LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.10, blue: 0.18), // Deep purple-navy
                Color(red: 0.09, green: 0.13, blue: 0.24), // Purple-teal
                Color(red: 0.06, green: 0.20, blue: 0.38)  // Teal-blue
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Card backgrounds with glass effect
        static let cardBackground = LinearGradient(
            colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Featured card background
        static let featuredCardBackground = LinearGradient(
            colors: [
                primary.opacity(0.15),
                primary.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // MARK: - Text Colors
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.8)
        static let textTertiary = Color.white.opacity(0.6)
        static let textDisabled = Color.white.opacity(0.4)
        
        // MARK: - UI Element Colors
        static let success = Color.statusSuccess // Use existing
        static let error = Color.statusError // Use existing
        static let warning = Color.statusWarning // Use existing
        static let info = Color(red: 0.45, green: 0.73, blue: 1.0)
        
        // MARK: - Coin Colors
        static let yellowCoin = Color(red: 1.0, green: 0.85, blue: 0.24)
        static let greenCoin = primary
        
        // MARK: - Component Backgrounds
        static let buttonPrimary = LinearGradient(
            colors: [primary, primaryDark],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let buttonSecondary = LinearGradient(
            colors: [
                Color.white.opacity(0.15),
                Color.white.opacity(0.05)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let inputBackground = Color.white.opacity(0.1)
        static let inputBorder = primary.opacity(0.5)
        
        // MARK: - Overlay Colors
        static let overlayLight = Color.black.opacity(0.3)
        static let overlayMedium = Color.black.opacity(0.5)
        static let overlayHeavy = Color.black.opacity(0.8)
    }
    
    // MARK: - Typography
    
    struct Typography {
        // MARK: - App Specific
        static let appTitle = Font.custom("SF Pro Display", size: 32)
            .weight(.bold)
        
        // MARK: - Headers
        static let largeTitle = Font.system(size: 28, weight: .bold)
        static let title1 = Font.system(size: 24, weight: .bold)
        static let title2 = Font.system(size: 20, weight: .bold)
        static let title3 = Font.system(size: 18, weight: .semibold)
        
        // MARK: - Body Text
        static let body = Font.system(size: 16, weight: .regular)
        static let bodyBold = Font.system(size: 16, weight: .semibold)
        static let callout = Font.system(size: 14, weight: .medium)
        static let caption = Font.system(size: 12, weight: .medium)
        static let footnote = Font.system(size: 10, weight: .regular)
        
        // MARK: - Special Purpose
        static let amount = Font.system(size: 20, weight: .bold, design: .monospaced)
        static let amountLarge = Font.system(size: 24, weight: .bold, design: .monospaced)
        static let countdown = Font.system(size: 18, weight: .bold, design: .monospaced)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let circular: CGFloat = 50
    }
    
    // MARK: - Shadows
    
    struct Shadow {
        static let light = (
            color: Color.black.opacity(0.1),
            radius: CGFloat(4),
            x: CGFloat(0),
            y: CGFloat(2)
        )
        
        static let medium = (
            color: Color.black.opacity(0.2),
            radius: CGFloat(8),
            x: CGFloat(0),
            y: CGFloat(4)
        )
        
        static let heavy = (
            color: Color.black.opacity(0.3),
            radius: CGFloat(12),
            x: CGFloat(0),
            y: CGFloat(6)
        )
        
        static let glow = (
            color: Colors.primary.opacity(0.3),
            radius: CGFloat(8),
            x: CGFloat(0),
            y: CGFloat(0)
        )
    }
    
    // MARK: - Animations
    
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let springQuick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
    }
    
    // MARK: - Effects
    
    struct Effects {
        // Glass morphism effect
        static func glassMorphism(opacity: Double = 0.1) -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.white.opacity(opacity))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .background(.ultraThinMaterial)
        }
        
        // Neon glow effect
        static func neonGlow(color: Color = Colors.primary, radius: CGFloat = 8) -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(color, lineWidth: 1)
                .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
                .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
        }
        
        // Shimmer loading effect
        static func shimmer() -> some View {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.0),
                    Color.white.opacity(0.3),
                    Color.white.opacity(0.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - View Modifiers

extension View {
    // Apply card styling with glass effect
    func cardStyle(padding: CGFloat = AppTheme.Spacing.md,
                   radius: CGFloat = AppTheme.CornerRadius.medium) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(AppTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(
                color: AppTheme.Shadow.light.color,
                radius: AppTheme.Shadow.light.radius,
                x: AppTheme.Shadow.light.x,
                y: AppTheme.Shadow.light.y
            )
    }
    
    // Apply featured card styling
    func featuredCardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(AppTheme.Colors.featuredCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(
                color: AppTheme.Colors.primary.opacity(0.2),
                radius: 12,
                x: 0,
                y: 6
            )
    }
    
    // Apply primary button styling
    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        self
            .font(AppTheme.Typography.bodyBold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isEnabled ? AppTheme.Colors.buttonPrimary : AppTheme.Colors.buttonSecondary)
            )
            .scaleEffect(isEnabled ? 1.0 : 0.95)
            .animation(AppTheme.Animation.quick, value: isEnabled)
    }
    
    // Apply input field styling
    func inputFieldStyle() -> some View {
        self
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.inputBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.inputBorder, lineWidth: 1)
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // Apply shimmer loading effect
    func shimmerLoading(_ isLoading: Bool) -> some View {
        self
            .overlay(
                Group {
                    if isLoading {
                        AppTheme.Effects.shimmer()
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                    }
                }
            )
    }
    
    // Apply error handling
    func errorHandling<T: ObservableObject>(viewModel: T) -> some View {
        self
        // Note: Implement error handling based on your viewModel structure
    }
}

// MARK: - Color Extensions (Compatible with existing)

extension Color {
    // Create lighter/darker variations
    func lighter(by percentage: Double = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
    
    func darker(by percentage: Double = 0.2) -> Color {
        return self.opacity(1.0 + percentage)
    }
}

// MARK: - Haptic Manager

class HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Custom Components

struct GradientText: View {
    let text: String
    let gradient: LinearGradient
    let font: Font
    
    init(_ text: String,
         gradient: LinearGradient = LinearGradient(
            colors: [AppTheme.Colors.primary, AppTheme.Colors.secondary],
            startPoint: .leading,
            endPoint: .trailing
         ),
         font: Font = AppTheme.Typography.title1) {
        self.text = text
        self.gradient = gradient
        self.font = font
    }
    
    var body: some View {
        Text(text)
            .font(font)
            .overlay(
                gradient
                    .mask(
                        Text(text)
                            .font(font)
                    )
            )
    }
}

struct PulsingView: View {
    @State private var isPulsing = false
    let color: Color
    let duration: Double
    
    init(color: Color = AppTheme.Colors.primary, duration: Double = 1.0) {
        self.color = color
        self.duration = duration
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0.3 : 1.0)
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Preview Helper

#if DEBUG
struct AppTheme_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Background preview
            Rectangle()
                .fill(AppTheme.Colors.background)
                .frame(height: 100)
                .overlay(
                    Text("Background Gradient")
                        .foregroundColor(.white)
                        .font(AppTheme.Typography.title2)
                )
            
            // Card preview
            VStack {
                Text("Sample Card")
                    .foregroundColor(.white)
                Text("With glass morphism effect")
                    .foregroundColor(.white.opacity(0.7))
                    .font(AppTheme.Typography.caption)
            }
            .cardStyle()
            
            // Button preview
            Text("Primary Button")
                .primaryButtonStyle()
            
            // Gradient text preview
            GradientText("BettorOdds", font: AppTheme.Typography.appTitle)
        }
        .padding()
        .background(AppTheme.Colors.background)
    }
}
#endif
