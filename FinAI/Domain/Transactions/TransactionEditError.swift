//
//  TransactionEditError.swift
//  FinAI
//
//  Created by Tommy on 07.10.26.
//

enum TransactionEditError: Error, Equatable, Sendable {
    case missingMerchant, invalidAmount, invalidCurrency, invalidDate, invalidDirection, invalidAccount
    case unsupportedTotals, storageChanged, saving
}
