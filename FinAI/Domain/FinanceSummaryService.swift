//
//  FinanceSummaryService.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct FinanceSummaryService: Sendable {
    /// Half-open interval prevents midnight transactions appearing in two periods.
    /// Net flow here is income minus expenses plus refunds, not an account balance.
    func summarize(_ transactions: [Transaction], from start: Date, to end: Date) throws -> [CurrencySummary] {
        let grouped = Dictionary(grouping: transactions.filter { $0.date >= start && $0.date < end }) {
            $0.money.currency
        }
        return try grouped.keys.sorted { $0.code < $1.code }.map { currency in
            var income = Money.zero(currency)
            var expenses = Money.zero(currency)
            var refunds = Money.zero(currency)
            for transaction in grouped[currency, default: []] {
                switch transaction.kind {
                case .income: income = try income.adding(transaction.money)
                case .expense: expenses = try expenses.adding(transaction.money)
                case .refund: refunds = try refunds.adding(transaction.money)
                case .transfer, .adjustment, .unknown: break
                }
            }
            let netSpending = try expenses.subtracting(refunds)
            return try CurrencySummary(
                currency: currency, income: income, expenses: expenses, refunds: refunds,
                netSpending: netSpending, netFlow: income.subtracting(netSpending)
            )
        }
    }
}
