//
//  FinancialAssistant.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import Foundation

/// Read-only tools. Model output selects a query; Swift owns its scope and arithmetic.
struct FinancialAssistant: Sendable {
    func answer(_ query: AssistantQuery, snapshot: FinanceSnapshot, date: Date, calendar: Calendar) throws -> AssistantAnswer {
        try Task.checkCancellation()
        var resolved = query
        let transactions: [Transaction]
        if query.kind == .merchant {
            guard let supplied = query.merchant else { throw AssistantError.unsupportedQuestion }
            let requested = supplied.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !requested.isEmpty else { throw AssistantError.unsupportedQuestion }
            let saved = Set(snapshot.transactions.map(\.merchant))
            let matches: Set<String>
            if saved.contains(supplied) {
                matches = [supplied]
            } else if saved.contains(requested) {
                matches = [requested]
            } else {
                matches = saved.filter {
                    $0.compare(requested, options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX")) == .orderedSame
                }
            }
            guard matches.count <= 1 else { throw AssistantError.ambiguousMerchant }
            guard let merchant = matches.first else { throw AssistantError.merchantNotFound }
            resolved.merchant = merchant
            transactions = snapshot.transactions.filter { $0.merchant == merchant }
        } else {
            guard query.merchant == nil else { throw AssistantError.unsupportedQuestion }
            transactions = snapshot.transactions
        }
        guard let currentMonth = calendar.dateInterval(of: .month, for: date),
              let selectedDate = calendar.date(byAdding: .month, value: query.period == .thisMonth ? 0 : -1, to: currentMonth.start) else {
            throw AssistantError.calculationFailed
        }
        let service = SpendingAnalyticsService()
        let report = try service.analyze(transactions, date: selectedDate, calendar: calendar)
        var changes: [CategorySpendingChange] = []
        if query.kind == .comparison {
            let previousRows = transactions.filter { $0.date >= report.previousMonth && $0.date < report.month }
            let previous = try service.analyze(previousRows, date: report.previousMonth, calendar: calendar)
            for currency in report.currencies {
                try Task.checkCancellation()
                let old = previous.currencies.first { $0.currency == currency.currency }
                for category in Category.allCases {
                    let current = currency.categories.first { $0.group == .category(category) }?.netSpending ?? .zero(currency.currency)
                    let prior = old?.categories.first { $0.group == .category(category) }?.netSpending ?? .zero(currency.currency)
                    let change = try current.subtracting(prior)
                    if change.amount != 0 { changes.append(CategorySpendingChange(category: category, change: change)) }
                }
            }
            changes.sort {
                if $0.change.currency != $1.change.currency { return $0.change.currency.code < $1.change.currency.code }
                if $0.change.amount != $1.change.amount { return $0.change.amount > $1.change.amount }
                return $0.category.rawValue < $1.category.rawValue
            }
        }
        try Task.checkCancellation()
        return AssistantAnswer(query: resolved, report: report, categoryChanges: changes)
    }
}
