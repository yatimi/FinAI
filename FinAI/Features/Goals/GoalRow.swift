//
//  GoalRow.swift
//  FinAI
//
//  Created by Tommy on 08.10.26.
//

import SwiftUI

struct GoalRow: View {
    let goal: SavingsGoal
    let plan: GoalPlan?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: goal.name).font(.headline)
            MoneyMetricRow(title: .goalTargetAmount, money: goal.target)
            MoneyMetricRow(title: .goalSavedAmount, money: goal.saved)
            LabeledContent(.goalDeadline) { Text(goal.deadline, format: .dateTime.day().month().year()) }
            if let plan {
                MoneyMetricRow(title: .goalRemainingAmount, money: plan.remaining)
                if let monthly = plan.monthlyContribution, plan.status == .active {
                    MoneyMetricRow(title: .goalMonthlyContribution, money: monthly)
                }
                if plan.status == .completed { Text(.goalCompleted).foregroundStyle(.secondary) }
                if plan.status == .overdue { Text(.goalOverdue).foregroundStyle(.secondary) }
            }
        }
    }
}
