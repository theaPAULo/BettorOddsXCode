//
//  AppError.swift
//  BettorOdds
//
//  Version: 1.3.0 - Final fix with explicit CoinType import
//  Updated: June 2025
//

import Foundation

// MARK: - App Error Types

/// Unified error system for the entire app
enum AppError: LocalizedError {
    
    // MARK: - Authentication Errors
    case authenticationFailed(String)
    case userNotFound
    case invalidCredentials
    case accountDisabled
    case authProviderError(String)
    
    // MARK: - Network Errors
    case noInternetConnection
    case serverUnreachable
    case requestTimeout
    case invalidResponse
    case apiKeyInvalid
    
    // MARK: - Database Errors
    case databaseError(String)
    case documentNotFound
    case permissionDenied
    case dataCorrupted
    case saveOperationFailed
    
    // MARK: - Betting Errors
    case insufficientFunds(String) // FIXED: Use String instead of CoinType to avoid ambiguity
    case dailyLimitExceeded
    case betAmountInvalid
    case gameNotAvailable
    case gameLocked
    case spreadChanged
    case matchingFailed
    case betCancellationFailed
    
    // MARK: - User Errors
    case userUpdateFailed
    case profileIncomplete
    case biometricAuthFailed
    case adminAccessDenied
    
    // MARK: - General Errors
    case unknown(String)
    case invalidInput(String)
    case operationCancelled
    case maintenance
    
    // MARK: - Error Descriptions
    
    var errorDescription: String? {
        switch self {
        // Authentication
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .userNotFound:
            return "User account not found. Please sign up first."
        case .invalidCredentials:
            return "Invalid login credentials. Please try again."
        case .accountDisabled:
            return "Your account has been disabled. Please contact support."
        case .authProviderError(let message):
            return "Sign-in provider error: \(message)"
            
        // Network
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .serverUnreachable:
            return "Unable to connect to our servers. Please try again later."
        case .requestTimeout:
            return "Request timed out. Please try again."
        case .invalidResponse:
            return "Received invalid response from server."
        case .apiKeyInvalid:
            return "API configuration error. Please contact support."
            
        // Database
        case .databaseError(let message):
            return "Database error: \(message)"
        case .documentNotFound:
            return "Requested data not found."
        case .permissionDenied:
            return "Permission denied. Please check your access rights."
        case .dataCorrupted:
            return "Data appears to be corrupted. Please try refreshing."
        case .saveOperationFailed:
            return "Failed to save data. Please try again."
            
        // Betting
        case .insufficientFunds(let coinType):
            return "Insufficient \(coinType). Please add more funds or use a different coin type."
        case .dailyLimitExceeded:
            return "You've reached your daily betting limit of $100. Please try again tomorrow."
        case .betAmountInvalid:
            return "Please enter a valid bet amount between $1 and $100."
        case .gameNotAvailable:
            return "This game is no longer available for betting."
        case .gameLocked:
            return "Betting is locked for this game. Please try a different game."
        case .spreadChanged:
            return "The spread has changed since you started placing this bet. Please review and try again."
        case .matchingFailed:
            return "Unable to find matching bets at this time. Please try again later."
        case .betCancellationFailed:
            return "Failed to cancel bet. Please contact support if this persists."
            
        // User
        case .userUpdateFailed:
            return "Failed to update user information. Please try again."
        case .profileIncomplete:
            return "Please complete your profile before continuing."
        case .biometricAuthFailed:
            return "Biometric authentication failed. Please try again or use your passcode."
        case .adminAccessDenied:
            return "Admin access required. Please contact support."
            
        // General
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .operationCancelled:
            return "Operation was cancelled."
        case .maintenance:
            return "App is currently under maintenance. Please try again later."
        }
    }
    
    // MARK: - Recovery Suggestions
    
    var recoverySuggestion: String? {
        switch self {
        case .insufficientFunds:
            return "Add more funds to your account or use a different coin type."
        case .dailyLimitExceeded:
            return "Your daily limit will reset tomorrow, or you can use Play Coins instead."
        case .gameLocked, .gameNotAvailable:
            return "Try betting on a different game."
        case .spreadChanged:
            return "Check the new spread and place your bet again if desired."
        case .biometricAuthFailed:
            return "You can use your passcode instead or try biometric authentication again."
        case .serverUnreachable, .requestTimeout:
            return "Wait a moment and try again."
        default:
            return "If the problem persists, please contact support."
        }
    }
    
    // MARK: - Error Categories
    
    /// Determines if this error requires user action
    var requiresUserAction: Bool {
        switch self {
        case .invalidCredentials, .insufficientFunds, .dailyLimitExceeded,
             .betAmountInvalid, .profileIncomplete, .invalidInput:
            return true
        default:
            return false
        }
    }
    
    /// Determines if this error should trigger a retry mechanism
    var isRetryable: Bool {
        switch self {
        case .noInternetConnection, .serverUnreachable, .requestTimeout,
             .databaseError, .matchingFailed, .userUpdateFailed:
            return true
        default:
            return false
        }
    }
    
    /// Determines if this error should be logged for debugging
    var shouldLog: Bool {
        switch self {
        case .operationCancelled:
            return false
        default:
            return true
        }
    }
    
    // MARK: - Convenience Static Methods
    
    /// Creates a Firebase authentication error
    static func firebaseAuth(_ error: Error) -> AppError {
        return .authenticationFailed(error.localizedDescription)
    }
    
    /// Creates a network error from URLError
    static func network(_ error: URLError) -> AppError {
        switch error.code {
        case .notConnectedToInternet:
            return .noInternetConnection
        case .timedOut:
            return .requestTimeout
        case .cannotConnectToHost:
            return .serverUnreachable
        default:
            return .unknown(error.localizedDescription)
        }
    }
    
    /// Creates a Firestore error
    static func firestore(_ error: Error) -> AppError {
        if error.localizedDescription.contains("permission") {
            return .permissionDenied
        } else if error.localizedDescription.contains("not found") {
            return .documentNotFound
        } else {
            return .databaseError(error.localizedDescription)
        }
    }
    
    /// Helper method to create insufficientFunds error with proper coin type
    static func insufficientCoins(of type: String) -> AppError {
        return .insufficientFunds(type)
    }
}

// MARK: - Equatable Conformance

extension AppError: Equatable {
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        // Authentication
        case (.authenticationFailed(let lhsMsg), .authenticationFailed(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.userNotFound, .userNotFound),
             (.invalidCredentials, .invalidCredentials),
             (.accountDisabled, .accountDisabled):
            return true
        case (.authProviderError(let lhsMsg), .authProviderError(let rhsMsg)):
            return lhsMsg == rhsMsg
            
        // Network
        case (.noInternetConnection, .noInternetConnection),
             (.serverUnreachable, .serverUnreachable),
             (.requestTimeout, .requestTimeout),
             (.invalidResponse, .invalidResponse),
             (.apiKeyInvalid, .apiKeyInvalid):
            return true
            
        // Database
        case (.databaseError(let lhsMsg), .databaseError(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.documentNotFound, .documentNotFound),
             (.permissionDenied, .permissionDenied),
             (.dataCorrupted, .dataCorrupted),
             (.saveOperationFailed, .saveOperationFailed):
            return true
            
        // Betting
        case (.insufficientFunds(let lhsCoin), .insufficientFunds(let rhsCoin)):
            return lhsCoin == rhsCoin
        case (.dailyLimitExceeded, .dailyLimitExceeded),
             (.betAmountInvalid, .betAmountInvalid),
             (.gameNotAvailable, .gameNotAvailable),
             (.gameLocked, .gameLocked),
             (.spreadChanged, .spreadChanged),
             (.matchingFailed, .matchingFailed),
             (.betCancellationFailed, .betCancellationFailed):
            return true
            
        // User
        case (.userUpdateFailed, .userUpdateFailed),
             (.profileIncomplete, .profileIncomplete),
             (.biometricAuthFailed, .biometricAuthFailed),
             (.adminAccessDenied, .adminAccessDenied):
            return true
            
        // General
        case (.unknown(let lhsMsg), .unknown(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.invalidInput(let lhsMsg), .invalidInput(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.operationCancelled, .operationCancelled),
             (.maintenance, .maintenance):
            return true
            
        default:
            return false
        }
    }
}

// MARK: - Result Extensions

extension Result where Failure == AppError {
    
    /// Maps a Result<Success, Error> to Result<Success, AppError>
    static func fromError<T>(_ result: Result<T, Error>) -> Result<T, AppError> {
        return result.mapError { AppError.unknown($0.localizedDescription) }
    }
}
