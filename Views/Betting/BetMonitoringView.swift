//
//  BetMonitoringView.swift
//  BettorOdds
//
//  Created by Assistant on 2/2/25
//  Version: 1.0.0
//

import SwiftUI
import Charts

struct BetMonitoringView: View {
    @StateObject private var viewModel = BetMonitoringViewModel()
    @State private var selectedTab = MonitoringTab.overview
    @State private var showMaintenanceAlert = false
    
    enum MonitoringTab {
        case overview
        case queue
        case risks
        case health
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with System Status
            systemStatusHeader
            
            // Tab Selection
            tabPicker
            
            // Main Content
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedTab {
                    case .overview:
                        overviewSection
                    case .queue:
                        queueSection
                    case .risks:
                        riskSection
                    case .health:
                        healthSection
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .alert("Maintenance Mode", isPresented: $showMaintenanceAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                Task {
                    try? await viewModel.cancelAllPendingBets()
                }
            }
        } message: {
            Text("This will cancel all pending bets and pause new matches. Are you sure?")
        }
    }
    
    // MARK: - Header
    private var systemStatusHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("System Status")
                    .font(.headline)
                Text(viewModel.systemHealth.status.rawValue)
                    .foregroundColor(Color(viewModel.systemHealth.status.color))
            }
            
            Spacer()
            
            Button(action: {
                showMaintenanceAlert = true
            }) {
                Label("Maintenance", systemImage: "wrench.fill")
            }
            .buttonStyle(.bordered)
            
            Button(action: {
                Task {
                    await viewModel.refreshData()
                }
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Tab Picker
    private var tabPicker: some View {
        Picker("View", selection: $selectedTab) {
            Text("Overview").tag(MonitoringTab.overview)
            Text("Queue").tag(MonitoringTab.queue)
            Text("Risks").tag(MonitoringTab.risks)
            Text("Health").tag(MonitoringTab.health)
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(spacing: 20) {
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Pending Bets",
                    value: "\(viewModel.stats.pendingBetsCount)",
                    trend: nil
                )
                
                StatCard(
                    title: "Match Success Rate",
                    value: "\(Int(viewModel.stats.matchSuccessRate))%",
                    trend: .up
                )
                
                StatCard(
                    title: "Hourly Volume",
                    value: "$\(Int(viewModel.stats.hourlyVolume))",
                    trend: viewModel.stats.volumeChange24h > 0 ? .up : .down
                )
                
                StatCard(
                    title: "Avg Match Time",
                    value: "\(Int(viewModel.stats.averageMatchTime))s",
                    trend: nil
                )
            }
            
            // Recent Activity Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("24h Volume")
                    .font(.headline)
                
                Chart {
                    // Sample data - replace with real data
                    ForEach(0..<24, id: \.self) { hour in
                        LineMark(
                            x: .value("Hour", hour),
                            y: .value("Volume", Double.random(in: 1000...5000))
                        )
                    }
                }
                .frame(height: 200)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Queue Section
    private var queueSection: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.queueItems) { item in
                QueueItemView(item: item) {
                    Task {
                        try? await viewModel.triggerMatching(for: item.bet.id)
                    }
                }
            }
        }
    }
    
    // MARK: - Risk Section
    private var riskSection: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.riskAlerts) { alert in
                RiskAlertView(alert: alert)
            }
        }
    }
    
    // MARK: - Health Section
    private var healthSection: some View {
        VStack(spacing: 20) {
            // System Metrics
            VStack(alignment: .leading, spacing: 8) {
                Text("System Metrics")
                    .font(.headline)
                
                MetricRow(
                    title: "Matching Latency",
                    value: String(format: "%.2fs", viewModel.systemHealth.matchingLatency)
                )
                
                MetricRow(
                    title: "Queue Processing",
                    value: "\(Int(viewModel.systemHealth.queueProcessingRate))%"
                )
                
                MetricRow(
                    title: "Error Rate",
                    value: "\(viewModel.systemHealth.errorRate)%"
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // Last 24h Error Log
            VStack(alignment: .leading, spacing: 8) {
                Text("Error Log")
                    .font(.headline)
                
                // Sample error log - replace with real data
                ForEach(0..<5) { _ in
                    ErrorLogRow(
                        timestamp: Date(),
                        message: "Sample error message"
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let trend: Trend?
    
    enum Trend {
        case up, down
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .foregroundColor(trend.color)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct QueueItemView: View {
    let item: BetQueueItem
    let onMatch: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.bet.team)
                    .font(.headline)
                Spacer()
                Text("\(item.bet.amount) coins")
                    .fontWeight(.semibold)
            }
            
            HStack {
                Label(
                    "\(Int(item.timeInQueue / 60))m in queue",
                    systemImage: "clock"
                )
                
                Spacer()
                
                Label(
                    "\(item.potentialMatches) potential",
                    systemImage: "person.2"
                )
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            Button("Force Match", action: onMatch)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct RiskAlertView: View {
    let alert: RiskAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(alert.severity.color))
                    .frame(width: 8, height: 8)
                
                Text(alert.type.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text(alert.timestamp, style: .relative)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(alert.details)
                .font(.subheadline)
            
            Text("User: \(alert.userId)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct ErrorLogRow: View {
    let timestamp: Date
    let message: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview Provider
struct BetMonitoringView_Previews: PreviewProvider {
    static var previews: some View {
        BetMonitoringView()
    }
}
