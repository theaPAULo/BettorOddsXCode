//
//  AdminDashboardView.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 2.1.0
//

import SwiftUI
import FirebaseFirestore

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    @State private var selectedTab = AdminTab.overview
    @State private var scrollOffset: CGFloat = 0  // Track scroll position
    
    // MARK: - Tab Enum
    enum AdminTab {
        case overview
        case users
        case bets
        case transactions
        
        var title: String {
            switch self {
            case .overview: return "Overview"
            case .users: return "Users"
            case .bets: return "Bets"
            case .transactions: return "Transactions"
            }
        }
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .users: return "person.2.fill"
            case .bets: return "dollarsign.circle.fill"
            case .transactions: return "arrow.left.arrow.right"
            }
        }
    }
    
    // MARK: - Scroll Tracking
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
    
    // MARK: - Body
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
                
                VStack(spacing: 0) {
                    // Admin Header
                    HStack {
                        Text("Admin Dashboard")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppTheme.Brand.primary)
                        Spacer()
                        Button(action: {
                            Task {
                                await viewModel.refreshData()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppTheme.Brand.primary)
                        }
                    }
                    .padding(.top, -60)
                    .padding(.horizontal)
                    
                    // Quick Actions Section
                    VStack(spacing: 12) {
                        // Game Management Button
                        NavigationLink(destination: AdminGameManagementView()) {
                            HStack {
                                Image(systemName: "gamecontroller.fill")
                                Text("Game Management")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color.backgroundSecondary)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    // Tab Selection
                    HStack(spacing: 0) {
                        ForEach([AdminTab.overview, .users, .bets, .transactions], id: \.self) { tab in
                            AdminTabButton(
                                title: tab.title,
                                icon: tab.icon,
                                isSelected: selectedTab == tab
                            ) {
                                withAnimation {
                                    selectedTab = tab
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case .overview:
                                AdminOverviewSection(stats: viewModel.stats)
                            case .users:
                                AdminUsersSection(users: viewModel.users)
                            case .bets:
                                AdminBetsSection(bets: viewModel.bets)
                            case .transactions:
                                AdminTransactionsSection(transactions: viewModel.transactions)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.refreshData()
                    }
                    .modifier(ScrollOffsetModifier(coordinateSpace: "scroll", offset: $scrollOffset))
                    .coordinateSpace(name: "scroll")
                }
            }
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .navigationBarHidden(true)
            .navigationViewStyle(StackNavigationViewStyle())

        }
    }
    
}

// MARK: - Supporting Views
struct AdminTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 12))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? AppTheme.Brand.primary.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? AppTheme.Brand.primary : .gray)
        }
    }
}

// MARK: - Preview
#Preview {
    AdminDashboardView()
}
