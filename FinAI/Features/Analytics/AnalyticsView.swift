//
//  AnalyticsView.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import ComposableArchitecture
import SwiftUI

struct AnalyticsView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        if let analytics = store.overview?.spending {
            List {
                Section {
                    Button("Regular payments", systemImage: "repeat") {
                        store.isRecurringPaymentsPresented = true
                    }
                    .accessibilityIdentifier("openRecurringPayments")
                }
                Section {
                    Text(analytics.month, format: .dateTime.month(.wide).year())
                        .font(.title2.bold())
                    Text("Current calendar month compared with the full previous month. The current month may be incomplete. Only saved transactions are included; missing activity is treated as zero.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if analytics.currencies.isEmpty {
                    Text("No expenses or refunds in these two months.")
                }
                ForEach(analytics.currencies) { spending in
                    Section(spending.currency.code) {
                        MoneyMetricRow(title: "Current month net spending", money: spending.current)
                        LabeledContent {
                            Text(analytics.previousMonth, format: .dateTime.month(.wide).year())
                        } label: { Text("Previous month") }
                        MoneyMetricRow(title: "Previous month net spending", money: spending.previous)
                        MoneyMetricRow(title: "Change in net spending", money: spending.change)
                        if let ratio = spending.changeRatio {
                            LabeledContent("Percentage change") {
                                Text(ratio, format: .percent.precision(.fractionLength(1)))
                            }
                        } else {
                            Text("Percentage change is unavailable when previous net spending is zero or negative.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Section {
                        ForEach(spending.categories) { row in
                            if case let .category(category) = row.group {
                                SpendingBreakdownRow(title: Text(category.title), row: row)
                            }
                        }
                    } header: {
                        Text("By category · \(spending.currency.code)")
                    }
                    Section {
                        ForEach(spending.merchants) { row in
                            if case let .merchant(merchant) = row.group {
                                SpendingBreakdownRow(
                                    title: merchant.isEmpty ? Text("Unknown merchant") : Text(verbatim: merchant), row: row
                                )
                            }
                        }
                    } header: {
                        Text("By merchant · \(spending.currency.code)")
                    }
                }
                Section {
                    Text("Breakdowns show the current month, ordered by net spending. Refunds reduce spending in their recorded month and category. Merchant names use saved values. Transfers, income, adjustments and unknown transactions are excluded.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("spendingAnalytics")
            .navigationDestination(isPresented: $store.isRecurringPaymentsPresented) {
                RecurringPaymentsView(store: store)
            }
        } else {
            ContentUnavailableView("Local data unavailable", systemImage: "chart.bar")
        }
    }
}
