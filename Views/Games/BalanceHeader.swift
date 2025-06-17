//
//  BalanceHeader.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//


//
//  BalanceHeader.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.0.0

import SwiftUI

struct BalanceHeader: View {
    let yellowCoins: Int
    let greenCoins: Int
    let dailyGreenCoinsUsed: Int
    
    var body: some View {
        HStack {
            Text("BettorOdds")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("Primary"))
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                // Coin Balances
                HStack(spacing: 12) {
                    // Yellow Coins
                    HStack(spacing: 4) {
                        Text("🟡")
                        Text("\(yellowCoins)")
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    // Green Coins
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.0, green: 0.9, blue: 0.79)) // Teal color
                        
                        Text("\(greenCoins)")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                
                // Daily Green Coin Usage
                Text("Daily Total: ") +
                Text(Image(systemName: "heart.fill")).foregroundColor(Color(red: 0.0, green: 0.9, blue: 0.79)) +
                Text("\(dailyGreenCoinsUsed)/100")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}
