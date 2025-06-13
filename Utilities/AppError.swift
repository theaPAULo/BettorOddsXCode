//
//  AppError.swift
//  BettorOdds
//
//  Created by Claude on 6/13/25
//  Version: 1.0.0 - Unified error handling system (corrected for existing CoinType)
//

import Foundation

// MARK: - App Error Types

/// Unified error system for the entire app
enum AppError: LocalizedError, Equatable {
    
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
    case insufficientFunds(CoinType)
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
            return "Failed to save changes. Please try again."
            
        // Betting
        case .insufficientFunds(let coinType):
            return "Insufficient \(coinType.displayName) for this bet."
        case .dailyLimitExceeded:
            return "You've reached your daily betting limit for green coins."
        case .betAmountInvalid:
            return "Bet amount must be between 1 and 100 coins."
        case .gameNotAvailable:
            return "This game is no longer available for betting."
        case .gameLocked:
            return "This game is locked and cannot accept new bets."
        case .spreadChanged:
            return "The spread has changed significantly. Please place your bet again."
        case .matchingFailed:
            return "Unable to match your bet. Please try again."
        case .betCancellationFailed:
            return "Unable to cancel bet. It may already be matched."
            
        // User
        case .userUpdateFailed:
            return "Failed to update user profile. Please try again."
        case .profileIncomplete:
            return "Please complete your profile before continuing."
        case .biometricAuthFailed:
            return "Biometric authentication failed. Please try again."
        case .adminAccessDenied:
            return "Admin access required for this action."
            
        // General
        case .unknown(let message):
            return message.isEmpty ? "An unknown error occurred." : message
        case .invalidInput(let field):
            return "Invalid input for \(field). Please check and try again."
        case .operationCancelled:
            return "Operation was cancelled."
        case .maintenance:
            return "The app is temporarily under maintenance. Please try again later."
        }
    }
    
    // MARK: - Failure Reason
    
    var failureReason: String? {
        switch self {
        case .authenticationFailed, .authProviderError:
            return "Authentication system error"
        case .noInternetConnection, .serverUnreachable, .requestTimeout:
            return "Network connectivity issue"
        case .databaseError, .dataCorrupted, .saveOperationFailed:
            return "Data storage issue"
        case .insufficientFunds, .dailyLimitExceeded, .betAmountInvalid:
            return "Betting validation error"
        case .gameLocked, .gameNotAvailable, .spreadChanged:
            return "Game status changed"
        default:
            return nil
        }
    }
    
    // MARK: - Recovery Suggestions
    
    var recoverySuggestion: String? {
        switch self {
        case .noInternetConnection:
            return "Check your internet connection and try again."
        case .authenticationFailed, .invalidCredentials:
            return "Verify your credentials and try signing in again."
        case .insufficientFunds:
            return "Add more coins to your account or reduce your bet amount."
        case .dailyLimitExceeded:
            return "Your daily limit will reset at midnight."
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
}

// MARK: - Result Extensions

extension Result where Failure == AppError {
    
    /// Maps a Result<Success, Error> to Result<Success, AppError>
    static func fromError<T>(_ result: Result<T, Error>) -> Result<T, AppError> {
        return result.mapError { AppError.unknown($0.localizedDescription) }
    }
}
