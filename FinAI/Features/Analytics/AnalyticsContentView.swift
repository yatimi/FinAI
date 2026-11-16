//
//  AnalyticsContentView.swift
//  FinAI
//
//  Created by Tommy on 16.10.26.
//

import ComposableArchitecture
import SwiftUI

struct AnalyticsContentView: View {
    @Bindable var store: StoreOf<AnalyticsFeature>
    let openRegularPayments: () -> Void

    var body: some View {
        if let analytics = store.report {
            List {
                Section {
                    Button(.regularPayments, systemImage: AppSymbol.recurringPayments.rawValue) {
                        openRegularPayments()
                    }
                    .accessibilityIdentifier(AccessibilityID.openRecurringPayments)
                }
                Section {
                    monthControls
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
                        Button { store.send(.spendingTapped(spending.currency, nil)) } label: {
                            HStack {
                                MoneyMetricRow(title: .currentMonthNetSpending, money: spending.current)
                                Image(systemName: AppSymbol.next.rawValue).foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
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
                    if !spending.categories.isEmpty || !spending.merchants.isEmpty {
                        Section {
                            SpendingChartView(days: spending.days, currency: spending.currency)
                                .environment(\.calendar, store.calendar)
                        } header: { Text(.dailyNetSpending) }
                    }
                    if spending.categories.isEmpty && spending.merchants.isEmpty {
                        Text(.noSpendingForCurrencyThisMonth(spending.currency.code))
                            .foregroundStyle(.secondary)
                    }
                    if !spending.categories.isEmpty {
                        Section {
                            ForEach(spending.categories) { row in
                                if case let .category(category) = row.group {
                                    Button { store.send(.spendingTapped(spending.currency, row.group)) } label: {
                                        SpendingBreakdownRow(title: Text(category.title), row: row)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } header: {
                            Text(.categoryBreakdownHeading(spending.currency.code))
                        }
                    }
                    if !spending.merchants.isEmpty {
                        Section {
                            ForEach(spending.merchants) { row in
                                if case let .merchant(merchant) = row.group {
                                    Button { store.send(.spendingTapped(spending.currency, row.group)) } label: {
                                        SpendingBreakdownRow(
                                            title: merchant.isEmpty ? Text(.unknownMerchant) : Text(verbatim: merchant), row: row
                                        ).contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } header: {
                            Text(.merchantBreakdownHeading(spending.currency.code))
                        }
                    }
                }
                Section {
                    Text(.spendingBreakdownExplanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier(AccessibilityID.spendingAnalytics)
            .navigationDestination(isPresented: $store.isDrilldownPresented) {
                SpendingTransactionsView(store: store)
            }
        } else if store.hasFailure {
            ContentUnavailableView {
                Label(.localDataUnavailable, systemImage: AppSymbol.overview.rawValue)
            } actions: {
                Button(.tryAgain) { store.send(.retryTapped) }
                if store.selectedMonth != nil {
                    Button(.thisMonth) { store.send(.currentMonthTapped) }
                }
            }
        } else {
            FinanceLoadingState(title: .loadingLocalData)
        }
    }

    private var monthControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack { previousMonth; Spacer(); currentMonth; Spacer(); nextMonth }
            VStack(alignment: .leading) { previousMonth; currentMonth; nextMonth }
        }
        .buttonStyle(.borderless)
    }

    private var previousMonth: some View {
        Button(.previousMonth, systemImage: AppSymbol.previous.rawValue) { store.send(.moveMonth(-1)) }
    }

    private var currentMonth: some View {
        Button(.thisMonth) { store.send(.currentMonthTapped) }
    }

    private var nextMonth: some View {
        Button(.nextMonth, systemImage: AppSymbol.next.rawValue) { store.send(.moveMonth(1)) }
    }
}
