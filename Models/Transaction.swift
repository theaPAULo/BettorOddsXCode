//
//  Transaction.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/28/25.
//  Version: 1.1.0
//

import Foundation
import FirebaseFirestore
/// Represents a financial transaction in the app
struct Transaction: Identifiable, Codable {
    // MARK: - Properties
    let id: String
    let userId: String
    let type: TxType
    let coinType: CoinType
    let amount: Double
    let betId: String?
    var status: TxStatus
    let createdAt: Date
    let description: String
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id
        case userId
        case type
        case coinType
        case amount
        case betId
        case status
        case createdAt
        case description
    }
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        userId: String,
        type: TxType,
        coinType: CoinType,
        amount: Double,
        betId: String? = nil,
        status: TxStatus = .pending,
        description: String
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.coinType = coinType
        self.amount = amount
        self.betId = betId
        self.status = status
        self.createdAt = Date()
        self.description = description
    }
    
    // MARK: - Firestore Conversion
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = document.documentID
        self.userId = data["userId"] as? String ?? ""
        self.amount = data["amount"] as? Double ?? 0.0
        self.betId = data["betId"] as? String
        self.description = data["description"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        
        guard let typeString = data["type"] as? String,
              let type = TxType(rawValue: typeString),
              let statusString = data["status"] as? String,
              let status = TxStatus(rawValue: statusString),
              let coinTypeString = data["coinType"] as? String,
              let coinType = CoinType(rawValue: coinTypeString) else {
            return nil
        }
        
        self.type = type
        self.status = status
        self.coinType = coinType
    }
    
    /// Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "type": type.rawValue,
            "coinType": coinType.rawValue,
            "amount": amount,
            "betId": betId as Any,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "description": description
        ]
    }
}
