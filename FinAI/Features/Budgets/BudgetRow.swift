//
//  BudgetRow.swift
//  FinAI
//
//  Created by Tommy on 09.10.26.
//

import SwiftUI

struct BudgetRow: View {
    let budget: CategoryBudget
    let progress: BudgetProgress?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(budget.category.title).font(.headline)
            MoneyMetricRow(title: .budgetLimit, money: budget.limit)
            if let progress {
                Text(progress.month, format: .dateTime.month(.wide).year()).foregroundStyle(.secondary)
                MoneyMetricRow(title: .budgetSpent, money: progress.spent)
                MoneyMetricRow(title: .budgetRemaining, money: progress.remaining)
                if progress.exceeded.amount > 0 {
                    MoneyMetricRow(title: .budgetExceeded, money: progress.exceeded)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}
