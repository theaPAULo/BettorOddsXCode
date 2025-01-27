//
//  CoinPurchaseView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//  Version: 2.0.0

import SwiftUI

struct CoinPurchaseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedAmount: Int?
    @State private var isProcessing = false
    
    let purchaseAmounts = [10, 25, 50, 100, 250, 500]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Info Section
                    VStack(spacing: 8) {
                        Text("Purchase Coins")
                            .font(.system(size: 24, weight: .bold))
                        Text("1 green coin = $1 USD")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                    .padding(.top)
                    
                    // Amount Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(purchaseAmounts, id: \.self) { amount in
                            PurchaseAmountCard(
                                amount: amount,
                                isSelected: selectedAmount == amount,
                                action: { selectedAmount = amount }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Purchase Button
                    CustomButton(
                        title: isProcessing ? "Processing..." : "Purchase Now",
                        action: handlePurchase,
                        isLoading: isProcessing,
                        disabled: selectedAmount == nil || isProcessing
                    )
                    .padding(.horizontal)
                    
                    // Terms
                    Text("By purchasing coins, you agree to our Terms of Service")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Text.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handlePurchase() {
        guard let amount = selectedAmount else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
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
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("💚")
                    .font(.system(size: 24))
                Text("\(amount)")
                    .font(.system(size: 20, weight: .bold))
                Text("$\(amount)")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Text.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? AppTheme.Brand.primary.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.Brand.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CoinPurchaseView()
}
