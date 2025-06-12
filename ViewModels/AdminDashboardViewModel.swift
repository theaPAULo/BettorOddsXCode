//
//  AdminDashboardViewModel.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 2.0.0 - Updated for Google/Apple Sign-In (no email field)
//

import SwiftUI
import FirebaseFirestore
import Combine

@MainActor
final class AdminDashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var stats = DashboardStats()
    @Published private(set) var users: [User] = []
    @Published private(set) var bets: [Bet] = []
    @Published private(set) var transactions: [Transaction] = []
    @Published var showError = false
    @Published var errorMessage: String?
    @Published private(set) var isLoading = false
    
    // MARK: - Services
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    init() {
        Task {
            await refreshData()
        }
    }
    
    // MARK: - Public Methods
    func refreshData() async {
        isLoading = true
        
        do {
            // Fetch all data concurrently
            async let usersTask = fetchUsers()
            async let betsTask = fetchBets()
            async let transactionsTask = fetchTransactions()
            
            // Wait for all fetches to complete
            (users, bets, transactions) = await (try usersTask, try betsTask, try transactionsTask)
            
            // Calculate statistics
            calculateStats()
            
        } catch {
            errorMessage = "Failed to refresh data: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    private func fetchUsers() async throws -> [User] {
        let snapshot = try await db.collection("users").getDocuments()
        return snapshot.documents.compactMap { document -> User? in
            try? document.data(as: User.self)
        }
    }
    
    private func fetchBets() async throws -> [Bet] {
        let snapshot = try await db.collection("bets")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> Bet? in
            try? document.data(as: Bet.self)
        }
    }
    
    private func fetchTransactions() async throws -> [Transaction] {
        let snapshot = try await db.collection("transactions")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> Transaction? in
            try? document.data(as: Transaction.self)
        }
    }
    
    private func calculateStats() {
        var newStats = DashboardStats()
        
        // Calculate active users (users who placed bets today)
        let today = Calendar.current.startOfDay(for: Date())
        newStats.activeUsers = users.filter { user in
            if let lastBet = user.lastBetDate {
                return Calendar.current.isDate(lastBet, inSameDayAs: today)
            }
            return false
        }.count
        
        // Calculate daily bets
        newStats.dailyBets = bets.filter { bet in
            Calendar.current.isDate(bet.createdAt, inSameDayAs: Date())
        }.count
        
        // Calculate revenue (from green coin bets)
        newStats.revenue = transactions
            .filter { $0.coinType == .green && $0.type == .bet }
            .reduce(0) { $0 + $1.amount }
        
        // Count pending bets
        newStats.pendingBets = bets.filter { $0.status == .pending }.count
        
        // Generate recent activity
        newStats.recentActivity = generateRecentActivity()
        
        stats = newStats
    }
    
    private func generateRecentActivity() -> [ActivityItem] {
        var activity: [ActivityItem] = []
        
        // Add recent bets
        bets.prefix(5).forEach { bet in
            activity.append(ActivityItem(
                type: .bet,
                description: "New bet: \(bet.amount) coins on \(bet.team)",
                time: formatTime(bet.createdAt)
            ))
        }
        
        // Add recent user activity - FIXED: Use displayName instead of email
        users.prefix(5).forEach { user in
            if let lastBet = user.lastBetDate {
                let userName = user.displayName ?? "Unknown User"
                let providerName = user.authProvider == "google.com" ? "Google" : "Apple"
                
                activity.append(ActivityItem(
                    type: .user,
                    description: "User activity: \(userName) (\(providerName))",
                    time: formatTime(lastBet)
                ))
            }
        }
        
        // Add recent transactions
        transactions.prefix(5).forEach { transaction in
            activity.append(ActivityItem(
                type: .transaction,
                description: "\(transaction.type.rawValue): \(transaction.amount) coins",
                time: formatTime(transaction.createdAt)
            ))
        }
        
        // Sort by time and limit to 10 most recent
        return activity
            .sorted { a, b in
                // Compare time strings in reverse order for most recent first
                return a.time > b.time
            }
            .prefix(10)
            .map { $0 }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    // Preview setup
    let viewModel = AdminDashboardViewModel()
    return AdminDashboardView()
        .environmentObject(viewModel)
}
