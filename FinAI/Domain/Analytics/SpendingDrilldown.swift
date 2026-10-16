//
//  SpendingDrilldown.swift
//  FinAI
//
//  Created by Tommy on 16.10.26.
//

import Foundation

/// Uses the same half-open month, saved grouping values and kinds as the report.
struct SpendingDrilldown: Equatable, Sendable {
    let month: Date
    let currency: Currency
    var group: SpendingBreakdown.Group?

    func transactions(in snapshot: FinanceSnapshot, calendar: Calendar) -> [Transaction] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        return snapshot.transactions.filter { row in
            guard row.money.currency == currency, row.kind == .expense || row.kind == .refund,
                  row.date >= interval.start, row.date < interval.end else { return false }
            switch group {
            case let .category(category): return row.category == category
            case let .merchant(merchant): return row.merchant == merchant
            case nil: return true
            }
        }.sorted { $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date > $1.date }
    }
}
