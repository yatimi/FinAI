//
//  TransactionEditService.swift
//  FinAI
//
//  Created by Tommy on 07.10.26.
//

import Foundation

struct TransactionEditService: Sendable {
    func replacing(_ expected: Transaction, with replacement: Transaction, in snapshot: FinanceSnapshot) throws -> FinanceSnapshot {
        guard let index = snapshot.transactions.firstIndex(where: { $0.id == expected.id }),
              snapshot.transactions[index] == expected,
              replacement.id == expected.id, replacement.source == expected.source,
              replacement.rawDescription == expected.rawDescription else { throw TransactionEditError.storageChanged }
        guard snapshot.accounts.contains(where: { $0.id == replacement.accountID }) else {
            throw TransactionEditError.invalidAccount
        }
        guard !replacement.merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TransactionEditError.missingMerchant
        }
        var result = snapshot
        result.transactions[index] = replacement
        if replacement != expected && result.originals[expected.id] == nil {
            result.originals[expected.id] = expected
        }
        try result.validate()
        // Protect all later financial aggregations against Decimal overflow/loss of precision.
        var totals: [Currency: Money] = [:]
        do {
            for transaction in result.transactions {
                totals[transaction.money.currency] = try (totals[transaction.money.currency] ?? .zero(transaction.money.currency)).adding(transaction.money)
            }
        } catch { throw TransactionEditError.unsupportedTotals }
        return result
    }
}
