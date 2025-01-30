//
//  StatusBadge.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/30/25.
//


//
//  StatusBadge.swift
//  BettorOdds
//
//  Created by Claude on 1/30/25
//  Version: 1.0.0
//

import SwiftUI

struct StatusBadge: View {
    let status: BetStatus
    
    private var statusColor: Color {
        switch status {
        case .pending:
            return .statusWarning
        case .active:
            return .primary
        case .cancelled:
            return .textSecondary
        case .won:
            return .statusSuccess
        case .lost:
            return .statusError
        }
    }
    
    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
}

#Preview {
    HStack {
        StatusBadge(status: .pending)
        StatusBadge(status: .active)
        StatusBadge(status: .won)
        StatusBadge(status: .lost)
        StatusBadge(status: .cancelled)
    }
    .padding()
}