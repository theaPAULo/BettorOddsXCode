//
//  RepositoryError.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/28/25.
//


//
//  RepositoryError.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/28/25.
//  Version: 1.0.0
//

import Foundation

/// Common errors for all repositories
enum RepositoryError: Error {
    case itemNotFound
    case saveFailed
    case networkError
    case cacheError
    case invalidData
    case operationNotSupported
    
    var localizedDescription: String {
        switch self {
        case .itemNotFound:
            return "The requested item was not found"
        case .saveFailed:
            return "Failed to save the item"
        case .networkError:
            return "Network error occurred"
        case .cacheError:
            return "Cache error occurred"
        case .invalidData:
            return "The data is invalid"
        case .operationNotSupported:
            return "This operation is not supported"
        }
    }
}