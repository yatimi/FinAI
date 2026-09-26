//
//  FinanceOverview.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct FinanceOverview: Equatable, Sendable {
    let snapshot: FinanceSnapshot
    let month: Date
    let summaries: [CurrencySummary]

    static func make(snapshot: FinanceSnapshot, date: Date, calendar: Calendar) throws -> Self {
        guard let interval = calendar.dateInterval(of: .month, for: date) else {
            throw ValidationError.invalidSnapshot
        }
        return try Self(
            snapshot: snapshot, month: interval.start,
            summaries: FinanceSummaryService().summarize(snapshot.transactions, from: interval.start, to: interval.end)
        )
    }
}
