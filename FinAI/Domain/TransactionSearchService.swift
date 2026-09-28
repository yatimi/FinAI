//
//  TransactionSearchService.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import Foundation

struct TransactionSearchService: Sendable {
    /// Preserves source order and original values. Every selected criterion must match.
    func search(
        _ transactions: [Transaction], query: TransactionQuery, now: Date, calendar: Calendar
    ) -> [Transaction] {
        let text = query.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let interval = dateInterval(query: query, now: now, calendar: calendar)
        guard query.period == .all || interval != nil else { return [] }
        return transactions.filter { transaction in
            if let accountID = query.accountID, transaction.accountID != accountID { return false }
            if let category = query.category, transaction.category != category { return false }
            if let kind = query.kind, transaction.kind != kind { return false }
            if let currency = query.currency, transaction.money.currency != currency { return false }
            if let interval, !(transaction.date >= interval.start && transaction.date < interval.end) { return false }
            return text.isEmpty || [transaction.merchant, transaction.rawDescription].contains {
                $0.range(of: text, options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX")) != nil
            }
        }
    }

    func dateInterval(query: TransactionQuery, now: Date, calendar: Calendar) -> DateInterval? {
        switch query.period {
        case .all:
            return nil
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)
        case .lastMonth:
            guard let month = calendar.dateInterval(of: .month, for: now),
                  let previous = calendar.date(byAdding: .month, value: -1, to: month.start) else { return nil }
            return calendar.dateInterval(of: .month, for: previous)
        case .custom:
            let start = calendar.startOfDay(for: query.startDate)
            let lastDay = calendar.startOfDay(for: query.endDate)
            guard start <= lastDay,
                  let end = calendar.date(byAdding: .day, value: 1, to: lastDay) else { return nil }
            return DateInterval(start: start, end: end)
        }
    }
}
