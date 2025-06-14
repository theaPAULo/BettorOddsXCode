//
//  ProfileView.swift
//  BettorOdds
//
//  Created by Claude on 2/2/25
//  Version: 3.0.0 - Updated for Google/Apple Sign-In authentication
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingCoinPurchase = false
    @State private var showingSettings = false
    @State private var scrollOffset: CGFloat = 0
    
    // MARK: - ScrollOffset Preference Key
    private struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    
    private struct ScrollOffsetModifier: ViewModifier {
        let coordinateSpace: String
        @Binding var offset: CGFloat
        
        func body(content: Content) -> some View {
            content
                .overlay(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: proxy.frame(in: .named(coordinateSpace)).minY
                            )
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    offset = value
                }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Primary").opacity(0.2),
                        Color.white.opacity(0.1),
                        Color("Primary").opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .hueRotation(.degrees(scrollOffset / 2))
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 12) {
                            // Profile Image (if available from provider)
                            if let profileImageURL = authViewModel.user?.profileImageURL,
                               let url = URL(string: profileImageURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle()
                                        .fill(Color("Primary").opacity(0.2))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Text(authViewModel.user?.displayName?.prefix(1).uppercased() ?? "U")
                                                .font(.system(size: 32, weight: .bold))
                                                .foregroundColor(Color("Primary"))
                                        )
                                }
                            } else {
                                // Fallback avatar with initials
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color("Primary"),
                                                Color("Primary").opacity(0.8)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text(authViewModel.user?.displayName?.prefix(1).uppercased() ?? "U")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: Color("Primary").opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            VStack(spacing: 4) {
                                Text("Profile")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(Color("Primary"))
                                    .padding(.top, -60) // Match MyBets spacing
                                
                                // Display name or fallback
                                Text(authViewModel.user?.displayName ?? "User")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color("Primary"))
                                
                                // Auth provider badge
                                if let user = authViewModel.user {
                                    HStack(spacing: 4) {
                                        Image(systemName: user.authProvider == "google.com" ? "globe" : "applelogo")
                                            .font(.system(size: 12))
                                        Text(user.authProvider == "google.com" ? "Google Account" : "Apple Account")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color("Primary").opacity(0.1))
                                    .foregroundColor(Color("Primary"))
                                    .cornerRadius(8)
                                }
                                
                                // Member since date
                                if let dateJoined = authViewModel.user?.dateJoined {
                                    Text("Member since \(dateJoined.formatted(.dateTime.month().year()))")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color("Primary").opacity(0.8))
                                }
                            }
                        }
                        
                        // Coin Balances
                        HStack(spacing: 16) {
                            // Yellow Coins
                            CoinBalanceCard(
                                type: .yellow,
                                balance: authViewModel.user?.yellowCoins ?? 0
                            )
                            
                            // Green Coins
                            CoinBalanceCard(
                                type: .green,
                                balance: authViewModel.user?.greenCoins ?? 0
                            )
                        }
                        .padding(.horizontal)
                        
                        // Quick Actions
                        VStack(spacing: 0) {
                            ActionButton(
                                title: "Buy Coins",
                                icon: "dollarsign.circle.fill"
                            ) {
                                showingCoinPurchase = true
                            }
                            
                            ActionButton(
                                title: "Transaction History",
                                icon: "clock.fill"
                            ) {
                                // Navigate to transaction history
                            }
                            
                            ActionButton(
                                title: "Settings",
                                icon: "gearshape.fill"
                            ) {
                                showingSettings = true
                            }
                            
                            ActionButton(
                                title: "Sign Out",
                                icon: "rectangle.portrait.and.arrow.right",
                                showDivider: false,
                                isDestructive: true
                            ) {
                                showSignOutConfirmation()
                            }
                        }
                        .background(AppTheme.Colors.background)
                        .cornerRadius(12)
                        .shadow(color: Color.backgroundPrimary.opacity(0.1), radius: 5)
                        .padding(.horizontal)
                    }
                }
                .modifier(ScrollOffsetModifier(coordinateSpace: "scroll", offset: $scrollOffset))
                .coordinateSpace(name: "scroll")
            }
        }
        .sheet(isPresented: $showingCoinPurchase) {
            CoinPurchaseView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .navigationBarHidden(true)
        .navigationViewStyle(StackNavigationViewStyle())

    }
    
    private func showSignOutConfirmation() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            authViewModel.signOut()
        })
        
        viewController.present(alert, animated: true)
    }
}

// Keeping existing supporting views unchanged
struct CoinBalanceCard: View {
    let type: CoinType
    let balance: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(type == .yellow ? "🟡" : "💚")
                    .font(.system(size: 24))
                Spacer()
                Text(balance.formatted())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            
            HStack {
                Text(type == .yellow ? "Play Coins" : "Real Coins")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                Spacer()
            }
        }
        .padding()
        .background(AppTheme.Colors.background)
        .cornerRadius(12)
        .shadow(color: Color.backgroundPrimary.opacity(0.1), radius: 5)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    var showDivider: Bool = true
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isDestructive ? .statusError : .primary)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(isDestructive ? .statusError : .textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            .padding()
        }
        
        if showDivider {
            Divider()
                .padding(.leading, 56)
                .background(AppTheme.Colors.background)
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(AuthenticationViewModel())
    }
}
