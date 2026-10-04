//
//  SpendingAnalyticsService.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import Foundation

struct SpendingAnalyticsService: Sendable {
    func analyze(_ transactions: [Transaction], date: Date, calendar: Calendar) throws -> SpendingAnalytics {
        guard let month = calendar.dateInterval(of: .month, for: date),
              let previousDate = calendar.date(byAdding: .month, value: -1, to: month.start),
              let previousMonth = calendar.dateInterval(of: .month, for: previousDate) else {
            throw ValidationError.invalidSnapshot
        }
        let spending = transactions.filter { $0.kind == .expense || $0.kind == .refund }
        let current = spending.filter { $0.date >= month.start && $0.date < month.end }
        let previous = spending.filter { $0.date >= previousMonth.start && $0.date < month.start }
        let summaryService = FinanceSummaryService()
        let currentSummaries = try summaryService.summarize(current, from: month.start, to: month.end)
        let previousSummaries = try summaryService.summarize(previous, from: previousMonth.start, to: month.start)
        let currencies = Set(currentSummaries.map(\.currency) + previousSummaries.map(\.currency))
        let results = try currencies.sorted { $0.code < $1.code }.map { currency in
            let currentTotal = currentSummaries.first { $0.currency == currency }?.netSpending ?? .zero(currency)
            let previousTotal = previousSummaries.first { $0.currency == currency }?.netSpending ?? .zero(currency)
            let change = try currentTotal.subtracting(previousTotal)
            let rows = current.filter { $0.money.currency == currency }
            return try MonthlySpending(
                currency: currency, current: currentTotal, previous: previousTotal, change: change,
                changeRatio: ratio(change: change.amount, baseline: previousTotal.amount),
                categories: breakdown(rows, currency: currency) { .category($0.category) },
                merchants: breakdown(rows, currency: currency) { .merchant($0.merchant) }
            )
        }
        return SpendingAnalytics(month: month.start, previousMonth: previousMonth.start, currencies: results)
    }

    private func breakdown(
        _ transactions: [Transaction], currency: Currency,
        group: (Transaction) -> SpendingBreakdown.Group
    ) throws -> [SpendingBreakdown] {
        try Dictionary(grouping: transactions, by: group).map { key, rows in
            var expenses = Money.zero(currency)
            var refunds = Money.zero(currency)
            for row in rows {
                if row.kind == .expense { expenses = try expenses.adding(row.money) }
                else { refunds = try refunds.adding(row.money) }
            }
            return try SpendingBreakdown(
                group: key, expenses: expenses, refunds: refunds, netSpending: expenses.subtracting(refunds)
            )
        }.sorted {
            if $0.netSpending.amount != $1.netSpending.amount { return $0.netSpending.amount > $1.netSpending.amount }
            return sortKey($0.group) < sortKey($1.group)
        }
    }

    private func sortKey(_ group: SpendingBreakdown.Group) -> String {
        switch group {
        case let .category(category): category.rawValue
        case let .merchant(merchant): merchant
        }
    }

    private func ratio(change: Decimal, baseline: Decimal) throws -> Decimal? {
        guard baseline > 0 else { return nil }
        var numerator = change
        var denominator = baseline
        var result = Decimal.zero
        let status = NSDecimalDivide(&result, &numerator, &denominator, .plain)
        // Repeating decimal ratios may round; monetary totals remain exact.
        guard status == .noError || status == .lossOfPrecision else { throw ValidationError.arithmeticFailure }
        return result
    }
}
