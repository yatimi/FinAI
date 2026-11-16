//
//  PlanBudgetSummary.swift
//  FinAI
//
//  Created by Tommy on 19.10.26.
//

import SwiftUI

struct PlanBudgetSummary: View {
    let budget: CategoryBudget
    let progress: BudgetProgress?

    var body: some View {
        VStack(alignment: .leading, spacing: FinanceStyle.Spacing.compact) {
            Text(budget.category.title).font(.headline)
            Text(verbatim: budget.limit.currency.code).font(.caption).foregroundStyle(.secondary)
            MoneyMetricRow(title: .budgetLimit, money: budget.limit)
            if let progress {
                Text(progress.month, format: .dateTime.month(.wide).year()).font(.caption).foregroundStyle(.secondary)
                MoneyMetricRow(title: .budgetSpent, money: progress.spent)
                MoneyProgressBar(value: progress.spent, total: budget.limit)
                    .tint(progress.exceeded.amount > 0 ? FinanceStyle.ColorRole.danger : FinanceStyle.ColorRole.accent)
                MoneyMetricRow(title: .budgetRemaining, money: progress.remaining)
                if progress.exceeded.amount > 0 {
                    MoneyMetricRow(title: .budgetExceeded, money: progress.exceeded)
                        .foregroundStyle(FinanceStyle.ColorRole.danger)
                }
            } else {
                Text(.planBudgetProgressUnavailable).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
