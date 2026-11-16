//
//  TransactionEditDraft.swift
//  FinAI
//
//  Created by Tommy on 07.10.26.
//

import Foundation

/// An unsaved correction. Source identity and original description cannot be changed here.
struct TransactionEditDraft: Equatable, Sendable {
    var merchant: String
    var date: Date
    var amount: String
    var currencyCode: String
    var accountID: UUID
    var direction: Transaction.Direction
    var kind: Transaction.Kind
    var category: Category
    var incomeKind: Transaction.IncomeKind?

    init(transaction: Transaction, locale: Locale) {
        merchant = transaction.merchant
        date = transaction.date
        amount = NSDecimalNumber(decimal: transaction.money.amount).stringValue
            .replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".")
        currencyCode = transaction.money.currency.code
        accountID = transaction.accountID
        direction = transaction.direction
        kind = transaction.kind
        category = transaction.category
        incomeKind = transaction.incomeKind
    }

    func transaction(replacing original: Transaction, locale: Locale) throws -> Transaction {
        let merchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !merchant.isEmpty else { throw TransactionEditError.missingMerchant }
        guard date.timeIntervalSinceReferenceDate.isFinite else { throw TransactionEditError.invalidDate }
        let amount: Decimal
        do {
            amount = try ImportValueParser().amount(self.amount, separator: locale.decimalSeparator == "," ? .comma : .dot)
            guard amount >= 0 else { throw TransactionEditError.invalidAmount }
        } catch { throw TransactionEditError.invalidAmount }
        let currency: Currency
        do { currency = try Currency(code: currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()) }
        catch { throw TransactionEditError.invalidCurrency }
        do {
            return try Transaction(
                id: original.id, accountID: accountID, date: date, merchant: merchant,
                rawDescription: original.rawDescription, money: Money(amount: amount, currency: currency),
                direction: direction, kind: kind, category: category,
                incomeKind: kind == .income ? incomeKind : nil, source: original.source
            )
        } catch { throw TransactionEditError.invalidDirection }
    }
}
