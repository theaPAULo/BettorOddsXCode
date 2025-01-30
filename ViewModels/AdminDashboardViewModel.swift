//
//  AdminDashboardViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/29/25.
//


//
//  AdminDashboardViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/29/25.
//  Version: 1.0.0
//

import SwiftUI
import FirebaseFirestore

@MainActor
class AdminDashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var stats = DashboardStats()
    @Published private(set) var users: [User] = []
    @Published private(set) var bets: [Bet] = []
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let db = Firestore.firestore()
    private let userService = UserService()
    private let betService = BetService()
    private let transactionService = TransactionService()
    
    // MARK: - Initialization
    init() {
        Task {
            await refreshData()
        }
    }
    
    // MARK: - Data Models
    struct DashboardStats {
        var activeUsers = 0
        var dailyBets = 0
        var revenue = 0.0
        var pendingBets = 0
        var recentActivity: [ActivityItem] = []
    }
    
    struct ActivityItem: Identifiable {
        let id = UUID()
        let type: ActivityType
        let description: String
        let time: String
        
        enum ActivityType {
            case bet, user, transaction
            
            var color: Color {
                switch self {
                case .bet: return .blue
                case .user: return .green
                case .transaction: return .orange
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Refreshes all dashboard data
    func refreshData() async {
        isLoading = true
        errorMessage = nil
        
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
        }
        
        isLoading = false
    }
    
    /// Exports current data to CSV
    func exportData(type: ExportType) async throws -> URL {
        switch type {
        case .users:
            return try await exportUsers()
        case .bets:
            return try await exportBets()
        case .transactions:
            return try await exportTransactions()
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchUsers() async throws -> [User] {
        // Fetch all users from Firestore
        let snapshot = try await db.collection("users").getDocuments()
        return snapshot.documents.compactMap { User(document: $0) }
    }
    
    private func fetchBets() async throws -> [Bet] {
        // Fetch recent bets
        let snapshot = try await db.collection("bets")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments()
        return snapshot.documents.compactMap { Bet(document: $0) }
    }
    
    private func fetchTransactions() async throws -> [Transaction] {
        // Fetch recent transactions
        let snapshot = try await db.collection("transactions")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments()
        return snapshot.documents.compactMap { Transaction(document: $0) }
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
        
        // Add recent transactions
        transactions.prefix(5).forEach { transaction in
            activity.append(ActivityItem(
                type: .transaction,
                description: "\(transaction.type.rawValue): \(transaction.amount) coins",
                time: formatTime(transaction.createdAt)
            ))
        }
        
        // Sort by time
        return activity.sorted { a, b in
            a.time > b.time
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Export Types
enum ExportType {
    case users, bets, transactions
}

// MARK: - Export Methods
extension AdminDashboardViewModel {
    private func exportUsers() async throws -> URL {
        let csvString = "ID,Email,Date Joined,Yellow Coins,Green Coins\n" +
        users.map { "\($0.id),\($0.email),\($0.dateJoined),\($0.yellowCoins),\($0.greenCoins)" }
            .joined(separator: "\n")
        
        return try saveToFile(csvString, filename: "users.csv")
    }
    
    private func exportBets() async throws -> URL {
        let csvString = "ID,User ID,Team,Amount,Status,Created At\n" +
        bets.map { "\($0.id),\($0.userId),\($0.team),\($0.amount),\($0.status),\($0.createdAt)" }
            .joined(separator: "\n")
        
        return try saveToFile(csvString, filename: "bets.csv")
    }
    
    private func exportTransactions() async throws -> URL {
        let csvString = "ID,User ID,Type,Coin Type,Amount,Status,Created At\n" +
        transactions.map { "\($0.id),\($0.userId),\($0.type),\($0.coinType),\($0.amount),\($0.status),\($0.createdAt)" }
            .joined(separator: "\n")
        
        return try saveToFile(csvString, filename: "transactions.csv")
    }
    
    private func saveToFile(_ content: String, filename: String) throws -> URL {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportPath = documentsPath.appendingPathComponent(filename)
        
        try content.write(to: exportPath, atomically: true, encoding: .utf8)
        return exportPath
    }
}
