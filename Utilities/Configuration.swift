//
//  Configuration.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Enhanced by Claude on 6/13/25
//  Version: 2.0.0 - Enhanced with comprehensive configuration management
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
    
    // MARK: - API Configuration (Your existing + enhanced)
    
    enum API {
        // Your existing API key
        static let oddsAPIKey = "a2358fa8aa8f101a940462e5d0f13581"
        static let oddsAPIBaseURL = "https://api.the-odds-api.com/v4"
        
        // Enhanced API settings
        static let oddsAPITimeout: TimeInterval = 30
        static let maxRequestsPerMinute = 60
        static let cacheTimeout: TimeInterval = 300 // 5 minutes
        
        // Sports endpoint - corrected structure
        static let sportsEndpoint = "https://api.the-odds-api.com/v4/sports"
    }
    
    // MARK: - Feature Flags (Your existing + enhanced)
    
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
        static let enableGameManagement = true
        static let enableUserManagement = true
        
        // Experimental features
        static let enableBetQueue = false
        static let enableLiveChat = false
        static let enableSocialFeatures = false
    }
    
    // MARK: - App Settings (Your existing + enhanced)
    
    enum Settings {
        // Your existing settings
        static let maxDailyBetAmount = 100.0
        static let warningThreshold = 0.8 // 80% of daily limit
        static let autoLogoutInterval: TimeInterval = 1800 // 30 minutes
        
        // Enhanced settings
        static let minBetAmount = 1
        static let maxBetAmount = 100
        static let dailyGreenCoinLimit = 100
        static let betCancellationWindowMinutes = 5
        static let spreadChangeThreshold = 1.0
        static let matchingTimeoutSeconds = 30
        
        // Starting coins for new users
        static let startingYellowCoins = 100
        static let startingGreenCoins = 0
        
        // Betting rules
        static let maxConsecutiveLosses = 3  // For loss streak protection
        static let lockoutHours = 24        // Hours to lock user after max losses
    }
    
    // MARK: - Firebase Configuration
    
    enum Firebase {
        static let timeout: TimeInterval = 30
        static let retryAttempts = 3
        static let retryDelay: TimeInterval = 1
        
        // Collection names
        static let usersCollection = "users"
        static let betsCollection = "bets"
        static let gamesCollection = "games"
        static let transactionsCollection = "transactions"
        static let settingsCollection = "settings"
        static let scoresCollection = "scores"
        
        // Batch sizes for queries
        static let defaultBatchSize = 50
        static let maxBatchSize = 100
    }
    
    // MARK: - UI Configuration
    
    enum UI {
        // Animation durations
        static let defaultAnimationDuration: TimeInterval = 0.3
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
    
    // MARK: - Security Configuration
    
    enum Security {
        // Session management (using your existing value)
        static let sessionTimeout: TimeInterval = Settings.autoLogoutInterval
        static let biometricTimeout: TimeInterval = 300 // 5 minutes
        
        // Admin features
        static let adminSessionTimeout: TimeInterval = 900 // 15 minutes
        static let requireBiometricForAdmin = Features.enableBiometrics
        static let requireBiometricForGreenCoins = Features.enableBiometrics
        
        // Rate limiting
        static let maxLoginAttempts = 5
        static let loginCooldownMinutes = 15
        static let maxBetsPerMinute = 10
    }
    
    // MARK: - Logging Configuration
    
    enum Logging {
        static let enableConsoleLogging = environment.isDevelopment
        static let enableFileLogging = true
        static let enableCrashReporting = environment.isProduction
        static let enableAnalytics = environment.isProduction
        
        // Log levels
        static let minLogLevel: LogLevel = environment.isDevelopment ? .debug : .info
        
        enum LogLevel: Int, CaseIterable {
            case debug = 0
            case info = 1
            case warning = 2
            case error = 3
            
            var name: String {
                switch self {
                case .debug: return "DEBUG"
                case .info: return "INFO"
                case .warning: return "WARNING"
                case .error: return "ERROR"
                }
            }
        }
    }
    
    // MARK: - App Information
    
    enum App {
        static var version: String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        }
        
        static var buildNumber: String {
            Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        }
        
        static var bundleIdentifier: String {
            Bundle.main.bundleIdentifier ?? "com.bettorodds.app"
        }
        
        static let supportEmail = "support@bettorodds.com"
        static let termsURL = "https://bettorodds.com/terms"
        static let privacyURL = "https://bettorodds.com/privacy"
        static let helpURL = "https://bettorodds.com/help"
    }
    
    // MARK: - Network Configuration
    
    enum Network {
        static let defaultTimeout: TimeInterval = 30
        static let uploadTimeout: TimeInterval = 60
        static let downloadTimeout: TimeInterval = 120
        
        // Retry configuration
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 2
        static let backoffMultiplier: Double = 2.0
        
        // Cache settings
        static let enableCaching = true
        static let cacheSize = 50 * 1024 * 1024  // 50MB
        static let cacheDuration: TimeInterval = 3600 // 1 hour
    }
    
    // MARK: - Development Configuration
    
    enum Development {
        // Debug features
        static let enableDebugMenu = environment.isDevelopment
        static let enableMockData = false
        static let enableNetworkLogging = environment.isDevelopment
        
        // Testing
        static let enableTestMode = false
        static let bypassAuthentication = false
        static let mockAPIResponses = false
    }
}

// MARK: - Configuration Validation

extension Configuration {
    
    /// Validates the current configuration
    static func validate() -> [String] {
        var errors: [String] = []
        
        // API Key validation
        if API.oddsAPIKey.isEmpty {
            errors.append("Odds API key is missing")
        }
        
        // Betting validation
        if Settings.minBetAmount >= Settings.maxBetAmount {
            errors.append("Invalid bet amount range")
        }
        
        if Settings.dailyGreenCoinLimit <= 0 {
            errors.append("Daily green coin limit must be positive")
        }
        
        // Timeout validation
        if API.oddsAPITimeout <= 0 || Firebase.timeout <= 0 {
            errors.append("Invalid timeout configuration")
        }
        
        return errors
    }
    
    /// Prints configuration summary for debugging
    static func printSummary() {
        guard Logging.enableConsoleLogging else { return }
        
        print("""
        
        📱 BettorOdds Configuration Summary
        ===================================
        Environment: \(environment.rawValue)
        Version: \(App.version) (\(App.buildNumber))
        Bundle: \(App.bundleIdentifier)
        
        🎲 Betting:
        - Min/Max Bet: \(Settings.minBetAmount)-\(Settings.maxBetAmount)
        - Daily Limit: \(Settings.dailyGreenCoinLimit)
        - Starting Coins: 💛\(Settings.startingYellowCoins) 💚\(Settings.startingGreenCoins)
        
        🔐 Security:
        - Session Timeout: \(Security.sessionTimeout)s
        - Biometric Required: \(Security.requireBiometricForGreenCoins)
        
        🎯 Feature Flags:
        - P2P Betting: \(Features.enableP2PBetting)
        - Admin Dashboard: \(Features.enableAdminDashboard)
        - Biometrics: \(Features.enableBiometrics)
        - Real Odds: \(Features.useRealOdds)
        
        ===================================
        """)
    }
}

// MARK: - Legacy Support (for backward compatibility)

extension Configuration {
    /// Legacy alias for backward compatibility
    enum AppConfiguration {
        static let environment = Configuration.environment
        static let Betting = Configuration.Settings.self
        static let API = Configuration.API.self
        static let Firebase = Configuration.Firebase.self
        static let UI = Configuration.UI.self
        static let Security = Configuration.Security.self
        static let Logging = Configuration.Logging.self
        static let FeatureFlags = Configuration.Features.self
        static let App = Configuration.App.self
        static let Network = Configuration.Network.self
        static let Development = Configuration.Development.self
    }
}
