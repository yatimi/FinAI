//
//  AssistantAnswerView.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import SwiftUI

struct AssistantAnswerView: View {
    let answer: AssistantAnswer
    let showTransactions: (Date, Currency) -> Void

    var body: some View {
        Section(.assistantAnswerScope) {
            Text(answer.query.kind == .comparison ? .assistantComparison : .netSpending)
                .font(.headline)
            Text(answer.report.month, format: .dateTime.month(.wide).year())
                .accessibilityIdentifier(AccessibilityID.assistantAnswerMonth)
            if let merchant = answer.query.merchant { Text(verbatim: merchant) }
            if let category = answer.query.category { Text(category.title) }
            if let excluded = answer.query.excludedMerchant {
                Text(.assistantExcludedMerchant).font(.headline)
                Text(verbatim: excluded)
                Text(.assistantExclusionExplanation).font(.footnote).foregroundStyle(.secondary)
            }
            Text(.assistantScopeExplanation).font(.footnote).foregroundStyle(.secondary)
            Text(.monthlyComparisonExplanation).font(.footnote).foregroundStyle(.secondary)
        }
        if answer.report.currencies.isEmpty {
            Section { Text(.noExpensesOrRefundsInTheseTwoMonths) }
        }
        ForEach(answer.report.currencies) { spending in
            Section(spending.currency.code) {
                MoneyMetricRow(title: .currentMonthNetSpending, money: spending.current)
                Button(.assistantViewTransactions) { showTransactions(answer.report.month, spending.currency) }
                    .accessibilityIdentifier("\(AccessibilityID.assistantCurrentTransactions)-\(spending.currency.code)")
                if answer.query.kind == .comparison {
                    LabeledContent(.previousMonth) {
                        Text(answer.report.previousMonth, format: .dateTime.month(.wide).year())
                    }
                    MoneyMetricRow(title: .previousMonthNetSpending, money: spending.previous)
                    MoneyMetricRow(title: .changeInNetSpending, money: spending.change)
                    if let ratio = spending.changeRatio {
                        LabeledContent(.percentageChange) { Text(ratio, format: .percent.precision(.fractionLength(1))) }
                    } else {
                        Text(.percentageChangeUnavailableExplanation).font(.footnote).foregroundStyle(.secondary)
                    }
                    Button(.assistantViewPreviousTransactions) { showTransactions(answer.report.previousMonth, spending.currency) }
                    let changes = answer.categoryChanges.filter { $0.change.currency == spending.currency }
                    Text(.assistantCategoryChanges).font(.headline)
                    if changes.isEmpty { Text(.assistantNoCategoryChanges) }
                    ForEach(changes) { change in
                        MoneyMetricRow(title: change.category.title, money: change.change)
                    }
                }
            }
        }
    }
}
