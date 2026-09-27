//
//  ImportBatch.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct ImportBatch: Equatable, Sendable {
    let id: UUID
    let sourceName: String
    let importedAt: Date
    let account: Account
    let transactions: [Transaction]
    let rowNumbers: [Int]
    let replacingDemo: Bool

    func validate(existingTransactions: [Transaction] = []) throws {
        guard !transactions.isEmpty,
              transactions.count == rowNumbers.count,
              Set(rowNumbers).count == rowNumbers.count,
              importedAt.timeIntervalSinceReferenceDate.isFinite,
              rowNumbers.allSatisfy({ $0 >= 2 }),
              transactions.allSatisfy({ $0.source == .imported && $0.accountID == account.id }),
              !account.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ImportError.emptySelection
        }
        try FinanceSnapshot(accounts: [account], transactions: transactions).validate()
        // Keep enough Decimal precision for totals as well as each individual amount.
        var totals: [Currency: Money] = [:]
        for transaction in existingTransactions + transactions {
            try Task.checkCancellation()
            let money = transaction.money
            do {
                totals[money.currency] = try (totals[money.currency] ?? .zero(money.currency)).adding(money)
            } catch {
                throw ImportError.unsupportedTotals
            }
        }
    }
}
