//
//  DashboardModels.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/30/25.
//


//
//  DashboardModels.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 1.0.0
//

import SwiftUI

// MARK: - Dashboard Stats
struct DashboardStats {
    var activeUsers: Int
    var dailyBets: Int
    var revenue: Double
    var pendingBets: Int
    var recentActivity: [ActivityItem]
    
    init(activeUsers: Int = 0,
         dailyBets: Int = 0,
         revenue: Double = 0.0,
         pendingBets: Int = 0,
         recentActivity: [ActivityItem] = []) {
        self.activeUsers = activeUsers
        self.dailyBets = dailyBets
        self.revenue = revenue
        self.pendingBets = pendingBets
        self.recentActivity = recentActivity
    }
}

// MARK: - Activity Item
struct ActivityItem: Identifiable {
    let id = UUID()
    let type: ActivityType
    let description: String
    let time: String
}

enum ActivityType {
    case bet, user, transaction
    
    var color: Color {
        switch self {
        case .bet:
            return .blue
        case .user:
            return .green
        case .transaction:
            return .orange
        }
    }
}
