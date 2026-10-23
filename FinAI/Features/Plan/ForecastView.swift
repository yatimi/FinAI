//
//  ForecastView.swift
//  FinAI
//
//  Created by Tommy on 23.10.26.
//

import ComposableArchitecture
import SwiftUI

struct ForecastView: View {
    let store: StoreOf<ForecastFeature>

    var body: some View {
        NavigationStack {
            List {
                if store.hasFailure {
                    Text(.forecastCalculationUnavailable)
                } else if let report = store.report {
                    Section {
                        LabeledContent { Text(report.month, format: .dateTime.month(.wide).year()) }
                            label: { Text(.forecastMonth) }
                        LabeledContent { Text(report.throughDay, format: .dateTime.day().month(.wide).year()) }
                            label: { Text(.forecastRecordedThrough) }
                        LabeledContent { Text(report.basisMonth, format: .dateTime.month(.wide).year()) }
                            label: { Text(.forecastHistoryMonth) }
                    } footer: { Text(.forecastSummaryExplanation) }
                    if report.currencies.isEmpty { Text(.forecastNoHistory) }
                    ForEach(report.currencies) { currency in
                        Section {
                            if let projection = currency.projection {
                                MoneyMetricRow(title: .forecastMonthNetSpending, money: projection.netSpending)
                                MoneyMetricRow(title: .forecastMonthNetFlow, money: projection.netFlow)
                                DisclosureGroup {
                                    MoneyMetricRow(title: .forecastRecordedExpenses, money: currency.recorded.expenses)
                                    MoneyMetricRow(title: .forecastRemainingVariable, money: projection.remainingVariableExpenses)
                                    MoneyMetricRow(title: .forecastRemainingRecurring, money: projection.remainingRecurringExpenses)
                                    MoneyMetricRow(title: .forecastRecordedRefunds, money: currency.recorded.refunds)
                                    MoneyMetricRow(title: .forecastTotalExpenses, money: projection.expenses)
                                    MoneyMetricRow(title: .forecastRecordedIncome, money: currency.recorded.income)
                                    MoneyMetricRow(title: .forecastRemainingIncome, money: projection.remainingIncome)
                                    MoneyMetricRow(title: .forecastTotalIncome, money: projection.income)
                                } label: { Text(.forecastCalculationDetails) }
                            } else {
                                Text(.forecastCurrencyHistoryMissing)
                                MoneyMetricRow(title: .forecastRecordedNetSpending, money: currency.recorded.netSpending)
                                MoneyMetricRow(title: .forecastRecordedNetFlow, money: currency.recorded.netFlow)
                            }
                        } header: { Text(currency.id) }
                    }
                    Section {
                        DisclosureGroup {
                            Text(.forecastMethodExplanation)
                            Text(.forecastLimitations)
                        } label: { Text(.forecastAssumptions) }
                    }
                } else {
                    Text(.forecastDataUnavailable)
                }
            }
            .scrollContentBackground(.hidden)
            .background(FinanceStyle.Surface.canvas)
            .navigationTitle(Text(.monthEndForecast))
            .toolbar { Button(.done) { store.send(.closeTapped) } }
        }
    }
}
