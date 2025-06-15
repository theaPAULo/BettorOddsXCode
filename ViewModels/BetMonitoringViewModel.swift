//
//  BetMonitoringViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 2/2/25.
//


//
//  BetMonitoringViewModel.swift
//  BettorOdds
//
//  Created by Assistant on 2/2/25
//  Version: 1.0.0
//

import SwiftUI
import FirebaseFirestore
import Combine

@MainActor
class BetMonitoringViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var stats = BetMonitoringStats()
    @Published private(set) var queueItems: [BetQueueItem] = []
    @Published private(set) var riskAlerts: [RiskAlert] = []
    @Published private(set) var systemHealth = SystemHealth(
        status: .healthy,
        matchingLatency: 0,
        queueProcessingRate: 0,
        errorRate: 0,
        lastUpdate: Date()
    )
    @Published private(set) var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private let refreshInterval: TimeInterval = 30 // 30 seconds
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    init() {
        setupListeners()
        startRefreshTimer()
    }
    
    // MARK: - Public Methods
    
    /// Refreshes all monitoring data
    func refreshData() async {
        isLoading = true
        
        do {
            async let statsTask = fetchStats()
            async let queueTask = fetchQueueItems()
            async let alertsTask = fetchRiskAlerts()
            async let healthTask = checkSystemHealth()
            
            let (newStats, newQueue, newAlerts, newHealth) = await (
                try statsTask,
                try queueTask,
                try alertsTask,
                try healthTask
            )
            
            stats = newStats
            queueItems = newQueue
            riskAlerts = newAlerts
            systemHealth = newHealth
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    /// Manually triggers matching for a specific bet
    func triggerMatching(for betId: String) async throws {
        let matchingService = BetMatchingService.shared
        
        // Change to optional binding
        if let bet = try await BetRepository().fetch(id: betId) {
            _ = try await matchingService.matchBet(bet)
            await refreshData()
        } else {
            throw NSError(domain: "", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Bet not found"
            ])
        }
    }
    
    
    
    /// Cancels all pending bets for maintenance
    func cancelAllPendingBets() async throws {
        let pendingBets = try await db.collection("bets")
            .whereField("status", in: ["pending", "partiallyMatched"])
            .getDocuments()
        
        for document in pendingBets.documents {
            guard let bet = Bet(document: document) else { continue }
            try await BetMatchingService.shared.cancelBet(bet)
        }
        
        await refreshData()
    }
    
    // MARK: - Private Methods
    
    private func setupListeners() {
        // Listen for new bets
        let betsListener = db.collection("bets")
            .whereField("status", in: ["pending", "partiallyMatched"])
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                Task {
                    await self.refreshData()
                }
            }
        
        // Listen for risk alerts
        let alertsListener = db.collection("riskAlerts")
            .whereField("timestamp", isGreaterThan: Timestamp(date: Date().addingTimeInterval(-3600)))
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                Task {
                    await self.refreshData()
                }
            }
        
        listeners.append(betsListener)
        listeners.append(alertsListener)
    }
    
    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task {
                await self.refreshData()
            }
        }
    }
    
    private func fetchStats() async throws -> BetMonitoringStats {
        var stats = BetMonitoringStats()
        
        // Fetch bet counts
        let pendingSnapshot = try await db.collection("bets")
            .whereField("status", in: ["pending", "partiallyMatched"])
            .count
            .getAggregation(source: .server)
        
        stats.pendingBetsCount = Int(truncating: pendingSnapshot.count)
        
        // Calculate volumes
        let hourAgo = Date().addingTimeInterval(-3600)
        _ = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        let hourlySnapshot = try await db.collection("bets")
            .whereField("createdAt", isGreaterThan: Timestamp(date: hourAgo))
            .getDocuments()
        
        stats.hourlyVolume = hourlySnapshot.documents
            .compactMap { Bet(document: $0) }
            .reduce(0) { $0 + Double($1.amount) }
        
        // More stat calculations...
        
        return stats
    }
    
    private func fetchQueueItems() async throws -> [BetQueueItem] {
        let snapshot = try await db.collection("bets")
            .whereField("status", in: ["pending", "partiallyMatched"])
            .order(by: "createdAt")
            .getDocuments()
        
        return try await withThrowingTaskGroup(of: BetQueueItem?.self) { group in
            for document in snapshot.documents {
                group.addTask {
                    guard let bet = Bet(document: document) else { return nil }
                    
                    // Find potential matches
                    let potentialMatches = try await BetMatchingService.shared
                        .findPotentialMatches(for: bet)
                        .count
                    
                    let timeInQueue = Date().timeIntervalSince(bet.createdAt)
                    
                    return BetQueueItem(
                        id: bet.id,
                        bet: bet,
                        timeInQueue: timeInQueue,
                        potentialMatches: potentialMatches,
                        estimatedMatchTime: timeInQueue * 1.5 // Simple estimation
                    )
                }
            }
            
            var items: [BetQueueItem] = []
            for try await item in group {
                if let item = item {
                    items.append(item)
                }
            }
            
            return items.sorted { $0.matchingScore > $1.matchingScore }
        }
    }
    
    private func fetchRiskAlerts() async throws -> [RiskAlert] {
        let snapshot = try await db.collection("riskAlerts")
            .whereField("timestamp", isGreaterThan: Timestamp(date: Date().addingTimeInterval(-3600)))
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> RiskAlert? in
            guard let data = document.data() as? [String: Any],
                  let userId = data["userId"] as? String,
                  let typeString = data["type"] as? String,
                  let type = RiskAlert.RiskAlertType(rawValue: typeString),
                  let severityInt = data["severity"] as? Int,
                  let severity = RiskAlert.RiskSeverity(rawValue: severityInt),
                  let details = data["details"] as? String,
                  let timestamp = (data["timestamp"] as? Timestamp)?.dateValue()
            else {
                return nil
            }
            
            return RiskAlert(
                id: document.documentID,
                userId: userId,
                type: type,
                severity: severity,
                timestamp: timestamp,
                details: details
            )
        }
    }
    
    private func checkSystemHealth() async throws -> SystemHealth {
        // Implement health checks...
        // For now, return placeholder
        return SystemHealth(
            status: .healthy,
            matchingLatency: 0.5,
            queueProcessingRate: 95.0,
            errorRate: 0.1,
            lastUpdate: Date()
        )
    }
    
    // MARK: - Cleanup
    deinit {
        listeners.forEach { $0.remove() }
        refreshTimer?.invalidate()
    }
}
