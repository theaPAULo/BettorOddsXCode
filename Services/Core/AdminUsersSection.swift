//
//  AdminUsersSection.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/29/25.
//


//
//  AdminSections.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/29/25.
//  Version: 1.0.0
//

import SwiftUI

// MARK: - Users Section
struct AdminUsersSection: View {
    let users: [User]
    @State private var searchText = ""
    @State private var showingExportOptions = false
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return users
        }
        return users.filter { user in
            user.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Search and Export
            HStack {
                SearchBar(text: $searchText, placeholder: "Search users...")
                
                Button(action: { showingExportOptions = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppTheme.Brand.primary)
                }
            }
            
            // Users List
            ForEach(filteredUsers) { user in
                UserRow(user: user)
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(type: .users)
        }
    }
}

// MARK: - Bets Section
struct AdminBetsSection: View {
    let bets: [Bet]
    @State private var searchText = ""
    @State private var showingExportOptions = false
    @State private var filterStatus: BetStatus?
    
    var filteredBets: [Bet] {
        bets.filter { bet in
            (filterStatus == nil || bet.status == filterStatus) &&
            (searchText.isEmpty || bet.userId.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Search and Filter
            HStack {
                SearchBar(text: $searchText, placeholder: "Search bets...")
                
                Menu {
                    Button("All") { filterStatus = nil }
                    ForEach(BetStatus.allCases, id: \.self) { status in
                        Button(status.rawValue) { filterStatus = status }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(AppTheme.Brand.primary)
                }
                
                Button(action: { showingExportOptions = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppTheme.Brand.primary)
                }
            }
            
            // Bets List
            ForEach(filteredBets) { bet in
                BetRow(bet: bet)
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(type: .bets)
        }
    }
}

// MARK: - Transactions Section
struct AdminTransactionsSection: View {
    let transactions: [Transaction]
    @State private var searchText = ""
    @State private var showingExportOptions = false
    @State private var filterType: TxType?
    
    var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            (filterType == nil || transaction.type == filterType) &&
            (searchText.isEmpty || transaction.userId.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Search and Filter
            HStack {
                SearchBar(text: $searchText, placeholder: "Search transactions...")
                
                Menu {
                    Button("All") { filterType = nil }
                    ForEach(TxType.allCases, id: \.self) { type in
                        Button(type.rawValue) { filterType = type }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(AppTheme.Brand.primary)
                }
                
                Button(action: { showingExportOptions = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppTheme.Brand.primary)
                }
            }
            
            // Transactions List
            ForEach(filteredTransactions) { transaction in
                TransactionRow(transaction: transaction)
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(type: .transactions)
        }
    }
}

// MARK: - Supporting Views

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct UserRow: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(user.email)
                    .font(.headline)
                Spacer()
                Text("Joined: \(user.dateJoined.formatted(.dateTime.month().day().year()))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                CoinDisplay(type: .yellow, amount: user.yellowCoins)
                CoinDisplay(type: .green, amount: user.greenCoins)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct BetRow: View {
    let bet: Bet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(bet.team)
                    .font(.headline)
                Spacer()
                StatusBadge(status: bet.status)
            }
            
            HStack {
                Text("\(bet.coinType.emoji) \(bet.amount)")
                    .font(.subheadline)
                Spacer()
                Text(bet.createdAt.formatted(.dateTime.month().day().hour().minute()))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(transaction.description)
                    .font(.headline)
                Spacer()
                Text(transaction.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(transaction.status == .completed ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .foregroundColor(transaction.status == .completed ? .green : .orange)
                    .cornerRadius(8)
            }
            
            HStack {
                Text("\(transaction.coinType.emoji) \(String(format: "%.2f", transaction.amount))")
                    .font(.subheadline)
                Spacer()
                Text(transaction.createdAt.formatted(.dateTime.month().day().hour().minute()))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct CoinDisplay: View {
    let type: CoinType
    let amount: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(type.emoji)
            Text("\(amount)")
                .font(.system(size: 16, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(type == .yellow ? Color.yellow.opacity(0.2) : Color.green.opacity(0.2))
        .cornerRadius(8)
    }
}

struct ExportOptionsView: View {
    let type: ExportType
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AdminDashboardViewModel()
    @State private var isExporting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export \(type.rawValue)")
                    .font(.headline)
                
                Button(action: exportData) {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Export as CSV")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.Brand.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isExporting)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
    
    private func exportData() {
        isExporting = true
        errorMessage = nil
        
        Task {
            do {
                let url = try await viewModel.exportData(type: type)
                // Handle successful export (e.g., share sheet)
                isExporting = false
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isExporting = false
            }
        }
    }
}

// MARK: - Extensions
extension ExportType: RawRepresentable {
    var rawValue: String {
        switch self {
        case .users: return "Users"
        case .bets: return "Bets"
        case .transactions: return "Transactions"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "Users": self = .users
        case "Bets": self = .bets
        case "Transactions": self = .transactions
        default: return nil
        }
    }
}