//
//  Configuration.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Enhanced by Claude on 6/13/25
//  Version: 2.0.1 - Fixed API key issue
//

import Foundation

/// Configuration management for the app
enum Configuration {
    
    // MARK: - Environment
    
    enum Environment: String, CaseIterable {
        case development = "development"
        case staging = "staging"
        case production = "production"
        
        var isDevelopment: Bool { self == .development }
        var isProduction: Bool { self == .production }
    }
    
    /// Current Environment
    static let environment: Environment = {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }()
    
    // MARK: - API Configuration - FIXED API KEY
    
    enum API {
        // CORRECTED: Use the working API key from ScoreService
        static let oddsAPIKey = "aec5b19b654411a05206d9d67dfb7764"
        static let oddsAPIBaseURL = "https://api.the-odds-api.com/v4"
        
        // Enhanced API settings
        static let oddsAPITimeout: TimeInterval = 30
        static let maxRequestsPerMinute = 60
        static let cacheTimeout: TimeInterval = 300 // 5 minutes
        
        // Sports endpoint - corrected structure
        static let sportsEndpoint = "https://api.the-odds-api.com/v4/sports"
    }
    
    // MARK: - Feature Flags
    
    enum Features {
        // Your existing features
        static let useRealOdds = true
        static let enableBiometrics = true
        static let autoRefreshInterval: TimeInterval = 300 // 5 minutes
        
        // Enhanced features
        static let enableP2PBetting = true
        static let enablePartialMatching = true
        static let enableBetCancellation = true
        static let enableSpreadUpdates = true
        static let enablePushNotifications = true
        static let enableDarkMode = true
        static let enableAdminDashboard = true
        static let enableSocialFeatures = false // Disabled for now
    }
    
    // MARK: - Betting Limits
    
    enum Betting {
        static let maxGreenCoinDailyLimit = 100.0
        static let minBetAmount = 1.0
        static let maxBetAmount = 50.0
        static let defaultBetAmount = 5.0
        static let maxBetsPerDay = 20
        static let betTimeoutMinutes = 15
    }
    
    // MARK: - User Interface
    
    enum UI {
        // MARK: - Layout and Design
        static let cardCornerRadius = 12.0
        static let defaultPadding = 16.0
        static let refreshCooldown: TimeInterval = 5.0 // Prevent rapid refresh
        
        // MARK: - Animation Durations
        static let animationDuration: TimeInterval = 0.3
        static let defaultAnimationDuration: TimeInterval = 0.3  // ADD THIS LINE
        static let fastAnimationDuration: TimeInterval = 0.15
        static let slowAnimationDuration: TimeInterval = 0.5
        
        // Loading states
        static let minLoadingTime: TimeInterval = 0.5  // Minimum time to show loading
        static let maxLoadingTime: TimeInterval = 10    // Max time before timeout
        
        // Auto-refresh intervals (using your existing value)
        static let gameRefreshInterval: TimeInterval = Features.autoRefreshInterval
        static let scoreRefreshInterval: TimeInterval = 30     // 30 seconds
        static let oddsRefreshInterval: TimeInterval = 120     // 2 minutes
        
        // Image caching
        static let imageCacheSize = 100 * 1024 * 1024  // 100MB
        static let imageCacheTimeout: TimeInterval = 3600 // 1 hour
    }
    
    // MARK: - Logging
    
    enum Logging {
        static let enableConsoleLogging = true
        static let enableFileLogging = environment.isDevelopment
        static let maxLogFileSize = 5 * 1024 * 1024 // 5MB
        
        enum LogLevel: Int {
            case debug = 0
            case info = 1
            case warning = 2
            case error = 3
        }
        
        static let minLogLevel: LogLevel = environment.isDevelopment ? .debug : .info
    }
    
    // MARK: - Firebase
    
    enum Firebase {
        static let timeoutInterval: TimeInterval = 30
        static let retryAttempts = 3
        static let offlineDataPersistence = true
    }
    
    // MARK: - Security
    
    enum Security {
        static let biometricTimeoutInterval: TimeInterval = 300 // 5 minutes
        static let sessionTimeoutInterval: TimeInterval = 3600 // 1 hour
        static let maxLoginAttempts = 5
        static let lockoutDuration: TimeInterval = 900 // 15 minutes
    }
}
