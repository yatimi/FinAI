//
//  PlanGoalSummary.swift
//  FinAI
//
//  Created by Tommy on 19.10.26.
//

import SwiftUI

struct PlanGoalSummary: View {
    let goal: SavingsGoal
    let plan: GoalPlan?

    var body: some View {
        VStack(alignment: .leading, spacing: FinanceStyle.Spacing.compact) {
            Text(verbatim: goal.name).font(.headline)
            Text(verbatim: goal.target.currency.code).font(.caption).foregroundStyle(.secondary)
            MoneyMetricRow(title: .goalSavedAmount, money: goal.saved)
            MoneyMetricRow(title: .goalTargetAmount, money: goal.target)
            MoneyProgressBar(value: goal.saved, total: goal.target)
                .tint(FinanceStyle.ColorRole.accent)
            if let plan {
                MoneyMetricRow(title: .goalRemainingAmount, money: plan.remaining)
                switch plan.status {
                case .active:
                    LabeledContent(.goalDeadline) { Text(goal.deadline, format: .dateTime.day().month().year()) }
                case .completed:
                    Text(.goalCompleted).foregroundStyle(FinanceStyle.ColorRole.success)
                case .overdue:
                    Text(.goalOverdue).foregroundStyle(FinanceStyle.ColorRole.warning)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
