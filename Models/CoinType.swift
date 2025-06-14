//
//  CoinType.swift
//  BettorOdds
//
//  Version: 1.2.0 - Final single definition to resolve all conflicts
//  Updated: June 2025
//

import Foundation

// MARK: - Single CoinType Definition (THE ONLY ONE)

enum CoinType: String, Codable, Equatable {
    case yellow = "yellow"
    case green = "green"
    
    var displayName: String {
        switch self {
        case .yellow:
            return "Play Coins"
        case .green:
            return "Real Coins"
        }
    }
    
    var emoji: String {
        switch self {
        case .yellow:
            return "🟡"
        case .green:
            return "💚"
        }
    }
    
    var isRealMoney: Bool {
        return self == .green
    }
    
    // Value in USD
    var value: Double {
        switch self {
        case .yellow:
            return 0.0
        case .green:
            return 1.0
        }
    }
}

// MARK: - CoinBalance Helper

struct CoinBalance {
    let type: CoinType
    let amount: Int
    
    var formattedAmount: String {
        return type == .green ? "$\(amount)" : "\(amount)"
    }
}

// MARK: - Preview Support

extension User {
    /// Preview instance for SwiftUI previews and testing
    static var preview: User {
        User(
            id: "preview-user-id",
            displayName: "John Doe",
            profileImageURL: nil,
            authProvider: "google.com"
        )
    }
    
    /// Preview instance with some betting history
    static var previewWithHistory: User {
        var user = User(
            id: "preview-user-with-history",
            displayName: "Jane Smith",
            profileImageURL: nil,
            authProvider: "apple.com"
        )
        
        // Add some coins and betting history
        user.yellowCoins = 75
        user.greenCoins = 25
        user.dailyGreenCoinsUsed = 15
        
        return user
    }
}
