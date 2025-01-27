//
//  CoinType.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//


// File: Models/CoinTypes.swift
import Foundation

enum CoinType: String, Codable {
    case yellow
    case green
    
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

struct CoinBalance {
    let type: CoinType
    let amount: Int
    
    var formattedAmount: String {
        return type == .green ? "$\(amount)" : "\(amount)"
    }
}
