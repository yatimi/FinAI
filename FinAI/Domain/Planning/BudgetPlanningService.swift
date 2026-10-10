//
//  BudgetPlanningService.swift
//  FinAI
//
//  Created by Tommy on 09.10.26.
//

import Foundation

struct BudgetPlanningService: Sendable {
    func progress(for budget: CategoryBudget, transactions: [Transaction], on date: Date, calendar: Calendar) throws -> BudgetProgress {
        try budget.validate()
        guard date.timeIntervalSinceReferenceDate.isFinite,
              let month = calendar.dateInterval(of: .month, for: date) else { throw ValidationError.invalidSnapshot }
        let rows = transactions.filter {
            $0.category == budget.category && $0.money.currency == budget.limit.currency
                && ($0.kind == .expense || $0.kind == .refund)
        }
        let totals = try FinanceSummaryService().summarize(rows, from: month.start, to: month.end)
        let spent = totals.first?.netSpending ?? .zero(budget.limit.currency)
        let remaining = try budget.limit.subtracting(spent)
        let exceeded = remaining.amount < 0 ? try Money.zero(budget.limit.currency).subtracting(remaining) : .zero(budget.limit.currency)
        return BudgetProgress(month: month.start, spent: spent, remaining: remaining, exceeded: exceeded)
    }
}
