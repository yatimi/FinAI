//
//  WhatIfFeatureTests.swift
//  FinAITests
//
//  Created by Tommy on 23.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct WhatIfFeatureTests {
    @Test func successiveScenariosUseTheBaselineAndDraftChangesClearOldResults() async throws {
        var initial = try state()
        initial.scenarioDraft.amount = "500"
        let report = try #require(initial.report)
        let expected = try WhatIfPlanningService().simulate(initial.scenarioDraft.scenario(locale: initial.locale), forecast: report)
        let store = TestStore(initialState: initial) { ForecastFeature() }
        await store.send(.simulateTapped) { $0.scenarioResult = expected }
        #expect(store.state.scenarioResult?.netFlowChange.amount == -500)
        await store.send(.binding(.set(\.scenarioDraft.amount, "200"))) {
            $0.scenarioDraft.amount = "200"
            $0.scenarioResult = nil
        }
        let second = try WhatIfPlanningService().simulate(store.state.scenarioDraft.scenario(locale: initial.locale), forecast: report)
        await store.send(.simulateTapped) { $0.scenarioResult = second }
        #expect(store.state.scenarioResult?.netFlowChange.amount == -200)
        await store.send(.simulateTapped)
        await store.send(.binding(.set(\.scenarioDraft.amount, "200")))
        #expect(store.state.scenarioResult?.netFlowChange.amount == -200)
        await store.send(.resetScenarioTapped) {
            $0.scenarioDraft = WhatIfDraft(currencyCode: "EUR")
            $0.scenarioResult = nil
        }
        #expect(store.state.report == report)
    }

    @Test func localizedInputIsParsedExactlyAndInvalidReductionExplainsTheLimit() async throws {
        var initial = try state()
        initial.locale = Locale(identifier: "de_DE")
        initial.scenarioDraft.amount = "12,50"
        let report = try #require(initial.report)
        let expected = try WhatIfPlanningService().simulate(initial.scenarioDraft.scenario(locale: initial.locale), forecast: report)
        let store = TestStore(initialState: initial) { ForecastFeature() }
        await store.send(.simulateTapped) { $0.scenarioResult = expected }
        #expect(store.state.scenarioResult?.scenario.money.amount == Decimal(string: "12.50"))
        await store.send(.binding(.set(\.scenarioDraft.change, .reducedExpenses))) {
            $0.scenarioDraft.change = .reducedExpenses
            $0.scenarioResult = nil
        }
        await store.send(.binding(.set(\.scenarioDraft.amount, "1000"))) { $0.scenarioDraft.amount = "1000" }
        await store.send(.simulateTapped) { $0.scenarioFailure = .remainingExpenses }
        #expect(store.state.scenarioResult == nil)
    }

    @Test func malformedAmountsAndMissingForecastNeverProduceAResult() async throws {
        var initial = try state()
        initial.scenarioDraft.amount = "1.2.3"
        let store = TestStore(initialState: initial) { ForecastFeature() }
        await store.send(.simulateTapped) { $0.scenarioFailure = .invalidAmount }
        await store.send(.binding(.set(\.scenarioDraft.amount, "-10"))) {
            $0.scenarioDraft.amount = "-10"
            $0.scenarioFailure = nil
        }
        await store.send(.simulateTapped) { $0.scenarioFailure = .invalidAmount }
        var empty = ForecastFeature.State()
        empty.scenarioDraft.amount = "10"
        let missing = TestStore(initialState: empty) { ForecastFeature() }
        await missing.send(.simulateTapped) { $0.scenarioFailure = .unavailable }
    }

    @Test func changedDataClearsTheResultAndMissingCurrencyClearsItsDraftAmount() throws {
        var state = try state()
        state.scenarioDraft.amount = "50"
        state.scenarioResult = try WhatIfPlanningService().simulate(state.scenarioDraft.scenario(locale: state.locale), forecast: #require(state.report))
        let originalReport = state.report
        let rows = try transactions() + [TestFixtures.transaction(amount: 10)]
        state.update(transactions: rows, date: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(state.report != originalReport)
        #expect(state.scenarioResult == nil)
        #expect(state.scenarioDraft.amount == "50")
        let usd = try transactions(currency: .usd)
        state.update(transactions: usd, date: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(state.scenarioDraft.currencyCode == "USD")
        #expect(state.scenarioDraft.amount.isEmpty)
        #expect(state.scenarioResult == nil)
        state.update(transactions: nil, date: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(state.scenarioCurrencies.isEmpty)
        #expect(state.scenarioResult == nil)
    }

    @Test func unchangedRefreshKeepsTheScenario() throws {
        var state = ForecastFeature.State()
        state.locale = Locale(identifier: "en_US")
        let rows = try transactions()
        state.update(transactions: rows, date: TestFixtures.date, calendar: TestFixtures.calendar)
        state.scenarioDraft.amount = "50"
        state.scenarioResult = try WhatIfPlanningService().simulate(
            state.scenarioDraft.scenario(locale: state.locale), forecast: #require(state.report))
        let expected = state.scenarioResult
        state.update(transactions: rows, date: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(state.scenarioResult == expected)
    }

    private func state() throws -> ForecastFeature.State {
        var state = ForecastFeature.State()
        state.locale = Locale(identifier: "en_US")
        state.update(transactions: try transactions(), date: TestFixtures.date, calendar: TestFixtures.calendar)
        return state
    }

    private func transactions(currency: Currency = .eur) throws -> [Transaction] {
        let prior = try #require(TestFixtures.calendar.date(byAdding: .month, value: -1, to: TestFixtures.date))
        return [try TestFixtures.transaction(amount: 310, currency: currency, date: prior),
                try TestFixtures.transaction(amount: 2000, currency: currency, kind: .income, date: prior),
                try TestFixtures.transaction(amount: 50, currency: currency),
                try TestFixtures.transaction(amount: 10, currency: currency, kind: .refund)]
    }
}
