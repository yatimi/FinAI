//
//  TransactionRecord.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import SwiftData

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
    /// Immutable snapshot taken before the first correction. Existing stores migrate with nil.
    var originalData: Data?

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

    func apply(_ transaction: Transaction) {
        accountID = transaction.accountID
        date = transaction.date
        merchant = transaction.merchant
        amount = NSDecimalNumber(decimal: transaction.money.amount).stringValue
        currencyCode = transaction.money.currency.code
        direction = transaction.direction.rawValue
        kind = transaction.kind.rawValue
        category = transaction.category.rawValue
        incomeKind = transaction.incomeKind?.rawValue
    }

    func domainValue() throws -> Transaction {
        guard let amount = Decimal(string: amount, locale: Locale(identifier: "en_US_POSIX")),
              let direction = Transaction.Direction(rawValue: direction),
              let kind = Transaction.Kind(rawValue: kind),
              let category = Category(rawValue: category),
              let source = Transaction.Source(rawValue: source) else {
            throw ValidationError.invalidSnapshot
        }
        let income = incomeKind.flatMap(Transaction.IncomeKind.init(rawValue:))
        guard incomeKind == nil || income != nil else { throw ValidationError.invalidSnapshot }
        return try Transaction(
            id: id, accountID: accountID, date: date, merchant: merchant, rawDescription: rawDescription,
            money: Money(amount: amount, currency: Currency(code: currencyCode)), direction: direction,
            kind: kind, category: category, incomeKind: income, source: source
        )
    }
}
