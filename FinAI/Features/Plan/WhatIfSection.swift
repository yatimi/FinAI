//
//  WhatIfSection.swift
//  FinAI
//
//  Created by Tommy on 23.10.26.
//

import ComposableArchitecture
import SwiftUI

struct WhatIfSection: View {
    @Bindable var store: StoreOf<ForecastFeature>
    var keyboardFocus: FocusState<Bool>.Binding

    var body: some View {
        Section {
            if store.scenarioCurrencies.isEmpty {
                Text(.whatIfNeedsForecast)
            } else {
                Picker(.whatIfChange, selection: $store.scenarioDraft.change) {
                    ForEach(WhatIfScenario.Change.allCases, id: \.self) { change in
                        Text(change.title).tag(change)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier(AccessibilityID.whatIfChange)
                Picker(.currency, selection: $store.scenarioDraft.currencyCode) {
                    ForEach(store.scenarioCurrencies) { currency in Text(currency.code).tag(currency.code) }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier(AccessibilityID.whatIfCurrency)
                TextField(.whatIfAmount, text: $store.scenarioDraft.amount)
                    .keyboardType(.decimalPad)
                    .focused(keyboardFocus)
                    .accessibilityIdentifier(AccessibilityID.whatIfAmount)
                Button(.whatIfCalculate) {
                    keyboardFocus.wrappedValue = false
                    store.send(.simulateTapped)
                }
                .accessibilityIdentifier(AccessibilityID.whatIfCalculate)
                if let failure = store.scenarioFailure {
                    Text(failure.message).foregroundStyle(FinanceStyle.ColorRole.danger)
                        .accessibilityIdentifier(AccessibilityID.whatIfError)
                }
                if !store.scenarioDraft.amount.isEmpty || store.scenarioResult != nil {
                    Button(.whatIfReset) {
                        keyboardFocus.wrappedValue = false
                        store.send(.resetScenarioTapped)
                    }
                    .accessibilityIdentifier(AccessibilityID.whatIfReset)
                }
            }
        } header: { Text(.whatIfTitle) } footer: { Text(.whatIfExplanation) }
        if let result = store.scenarioResult {
            Section {
                MoneyMetricRow(title: .whatIfBaselineSpending, money: result.baseline.netSpending)
                MoneyMetricRow(title: .whatIfScenarioSpending, money: result.netSpending)
                MoneyMetricRow(title: .whatIfBaselineFlow, money: result.baseline.netFlow)
                MoneyMetricRow(title: .whatIfScenarioFlow, money: result.netFlow)
                MoneyMetricRow(title: .whatIfFlowChange, money: result.netFlowChange)
            } header: { Text(.whatIfResultHeading(result.scenario.money.currency.code)) }
                footer: { Text(.whatIfResultExplanation) }
        }
    }
}
