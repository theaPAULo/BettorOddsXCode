//
//  BetMonitoringStats.swift
//  BettorOdds
//
//  Created by Paul Soni on 2/2/25.
//


//
//  BetMonitoringModels.swift
//  BettorOdds
//
//  Created by Assistant on 2/2/25
//  Version: 1.0.0
//

import Foundation

// MARK: - Monitoring Stats
struct BetMonitoringStats {
    // Queue Stats
    var pendingBetsCount: Int
    var averageMatchTime: TimeInterval
    var partiallyMatchedCount: Int
    var fullyMatchedCount: Int
    
    // Volume Stats
    var totalBetVolume: Double
    var hourlyVolume: Double
    var peakVolume: Double
    var volumeChange24h: Double
    
    // Health Stats
    var matchSuccessRate: Double
    var averageQueueDepth: Int
    var systemLatency: TimeInterval
    
    // Risk Metrics
    var suspiciousActivityCount: Int
    var rapidCancellationCount: Int
    var unusualPatternCount: Int
    
    init() {
        pendingBetsCount = 0
        averageMatchTime = 0
        partiallyMatchedCount = 0
        fullyMatchedCount = 0
        totalBetVolume = 0
        hourlyVolume = 0
        peakVolume = 0
        volumeChange24h = 0
        matchSuccessRate = 0
        averageQueueDepth = 0
        systemLatency = 0
        suspiciousActivityCount = 0
        rapidCancellationCount = 0
        unusualPatternCount = 0
    }
}

// MARK: - Queue Item
struct BetQueueItem: Identifiable {
    let id: String
    let bet: Bet
    let timeInQueue: TimeInterval
    let potentialMatches: Int
    let estimatedMatchTime: TimeInterval
    
    var matchingScore: Double {
        // Calculate matching priority based on multiple factors
        let timeWeight = min(timeInQueue / 3600, 1.0) * 0.4  // 40% weight for time
        let sizeWeight = min(Double(bet.amount) / 100.0, 1.0) * 0.3  // 30% weight for size
        let matchesWeight = min(Double(potentialMatches) / 5.0, 1.0) * 0.3  // 30% for potential matches
        
        return timeWeight + sizeWeight + matchesWeight
    }
}

// MARK: - Risk Alert
struct RiskAlert: Identifiable {
    let id: String
    let userId: String
    let type: RiskAlertType
    let severity: RiskSeverity
    let timestamp: Date
    let details: String
    
    enum RiskAlertType: String {
        case rapidCancellation = "Rapid Cancellation"
        case unusualVolume = "Unusual Volume"
        case suspiciousPattern = "Suspicious Pattern"
        case systemAnomaly = "System Anomaly"
    }
    
    enum RiskSeverity: Int {
        case low = 1
        case medium = 2
        case high = 3
        
        var color: String {
            switch self {
            case .low: return "yellow"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }
}

// MARK: - System Health
struct SystemHealth {
    var status: HealthStatus
    var matchingLatency: TimeInterval
    var queueProcessingRate: Double
    var errorRate: Double
    var lastUpdate: Date
    
    enum HealthStatus: String {
        case healthy = "Healthy"
        case degraded = "Degraded"
        case critical = "Critical"
        
        var color: String {
            switch self {
            case .healthy: return "green"
            case .degraded: return "yellow"
            case .critical: return "red"
            }
        }
    }
}