//
//  CoinPurchaseView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//  Version: 2.1.0 - Updated for EnhancedTheme compatibility

import SwiftUI

struct CoinPurchaseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedAmount: Int?
    @State private var isProcessing = false
    
    let purchaseAmounts = [10, 25, 50, 100, 250, 500]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Info Section
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Purchase Coins")
                            .font(AppTheme.Typography.largeTitle)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .fontWeight(.bold)
                        
                        Text("1 green coin = $1 USD")
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.top, AppTheme.Spacing.md)
                    
                    // Amount Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppTheme.Spacing.md) {
                        ForEach(purchaseAmounts, id: \.self) { amount in
                            PurchaseAmountCard(
                                amount: amount,
                                isSelected: selectedAmount == amount,
                                action: { selectedAmount = amount }
                            )
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    
                    // Purchase Button
                    CustomButton(
                        title: isProcessing ? "Processing..." : "Purchase Now",
                        action: handlePurchase,
                        isLoading: isProcessing,
                        disabled: selectedAmount == nil || isProcessing
                    )
                    .padding(.horizontal, AppTheme.Spacing.md)
                    
                    // Terms
                    Text("By purchasing coins, you agree to our Terms of Service")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.bottom, AppTheme.Spacing.md)
                }
            }
            .background(AppTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
    }
    
    private func handlePurchase() {
        guard let amount = selectedAmount else { return }
        
        HapticManager.impact(.medium)
        
        isProcessing = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            showPurchaseConfirmation(amount: amount)
        }
    }
    
    private func showPurchaseConfirmation(amount: Int) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let alert = UIAlertController(
            title: "Purchase Successful",
            message: "You have successfully purchased \(amount) green coins.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            dismiss()
        })
        
        viewController.present(alert, animated: true)
    }
}

struct PurchaseAmountCard: View {
    let amount: Int
    let isSelected: Bool
    let action: () -> Void
    
    private var cardBackground: some View {
        if isSelected {
            return LinearGradient(
                colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [AppTheme.Colors.cardBackground, AppTheme.Colors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                // Coin Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [AppTheme.Colors.greenCoin.opacity(0.2), AppTheme.Colors.greenCoin.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)
                    
                    Text("💚")
                        .font(.system(size: 24))
                }
                
                // Amount
                Text("\(amount)")
                    .font(AppTheme.Typography.amount)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                    .fontWeight(.bold)
                
                // Price
                Text("$\(amount)")
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(cardBackground)
            .cornerRadius(AppTheme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary.opacity(0.1),
                           lineWidth: isSelected ? 2 : 1)
            )
            .shadow(
                color: isSelected ? AppTheme.Colors.primary.opacity(0.2) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(AppTheme.Animation.springQuick, value: isSelected)
    }
}

#Preview {
    CoinPurchaseView()
}
