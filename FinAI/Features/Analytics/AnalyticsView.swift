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
                    Button(.regularPayments, systemImage: AppSymbol.recurringPayments.rawValue) {
                        store.isRecurringPaymentsPresented = true
                    }
                    .accessibilityIdentifier(AccessibilityID.openRecurringPayments)
                }
                Section {
                    Text(analytics.month, format: .dateTime.month(.wide).year())
                        .font(.title2.bold())
                    Text(.monthlyComparisonExplanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if analytics.currencies.isEmpty {
                    Text(.noExpensesOrRefundsInTheseTwoMonths)
                }
                ForEach(analytics.currencies) { spending in
                    Section(spending.currency.code) {
                        MoneyMetricRow(title: .currentMonthNetSpending, money: spending.current)
                        LabeledContent {
                            Text(analytics.previousMonth, format: .dateTime.month(.wide).year())
                        } label: { Text(.previousMonth) }
                        MoneyMetricRow(title: .previousMonthNetSpending, money: spending.previous)
                        MoneyMetricRow(title: .changeInNetSpending, money: spending.change)
                        if let ratio = spending.changeRatio {
                            LabeledContent(.percentageChange) {
                                Text(ratio, format: .percent.precision(.fractionLength(1)))
                            }
                        } else {
                            Text(.percentageChangeUnavailableExplanation)
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
                        Text(.categoryBreakdownHeading(spending.currency.code))
                    }
                    Section {
                        ForEach(spending.merchants) { row in
                            if case let .merchant(merchant) = row.group {
                                SpendingBreakdownRow(
                                    title: merchant.isEmpty ? Text(.unknownMerchant) : Text(verbatim: merchant), row: row
                                )
                            }
                        }
                    } header: {
                        Text(.merchantBreakdownHeading(spending.currency.code))
                    }
                }
                Section {
                    Text(.spendingBreakdownExplanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier(AccessibilityID.spendingAnalytics)
            .navigationDestination(isPresented: $store.isRecurringPaymentsPresented) {
                RecurringPaymentsView(store: store)
            }
        } else {
            ContentUnavailableView(.localDataUnavailable, systemImage: AppSymbol.overview.rawValue)
        }
    }
}
