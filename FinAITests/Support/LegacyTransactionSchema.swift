//
//  LegacyTransactionSchema.swift
//  FinAITests
//
//  Created by Tommy on 07.10.26.
//

import Foundation
import SwiftData
@testable import FinAI

/// Frozen pre-correction record, used to exercise migration of the real previous schema.
enum LegacyTransactionSchema {
    @Model
    final class TransactionRecord {
        @Attribute(.unique) var id: UUID
        var accountID: UUID
        var date: Date
        var merchant: String
        var rawDescription: String
        /// Canonical decimal text preserves the exact original amount without floating-point conversion.
        var amount: String
        var currencyCode: String
        var direction: String
        var kind: String
        var category: String
        var incomeKind: String?
        var source: String

        init(_ transaction: Transaction) {
            id = transaction.id
            accountID = transaction.accountID
            date = transaction.date
            merchant = transaction.merchant
            rawDescription = transaction.rawDescription
            amount = NSDecimalNumber(decimal: transaction.money.amount).stringValue
            currencyCode = transaction.money.currency.code
            direction = transaction.direction.rawValue
            kind = transaction.kind.rawValue
            category = transaction.category.rawValue
            incomeKind = transaction.incomeKind?.rawValue
            source = transaction.source.rawValue
        }
    }
}
