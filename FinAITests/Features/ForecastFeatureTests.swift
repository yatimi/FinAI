//
//  ForecastFeatureTests.swift
//  FinAITests
//
//  Created by Tommy on 23.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct ForecastFeatureTests {
    @Test func presentsForecastAndRecalculatesAfterCorrections() async throws {
        let date = TestFixtures.date
        let calendar = TestFixtures.calendar
        let prior = try #require(calendar.date(byAdding: .month, value: -1, to: date))
        let history = try TestFixtures.transaction(amount: 310, date: prior)
        var state = PlanFeature.State()
        state.transactions = [history]
        var forecast = ForecastFeature.State()
        forecast.update(transactions: [history], date: date, calendar: calendar)
        let store = TestStore(initialState: state) { PlanFeature() } withDependencies: {
            $0.date.now = date; $0.calendar = calendar
        }
        await store.send(.forecastTapped) { $0.forecast = forecast }
        let rows = [history, try TestFixtures.transaction(amount: 10)]
        forecast.update(transactions: rows, date: date, calendar: calendar)
        await store.send(.transactionsUpdated(rows)) { $0.transactions = rows; $0.forecast = forecast }
        await store.send(.forecast(.presented(.closeTapped)))
        await store.receive(.forecast(.dismiss)) { $0.forecast = nil }
    }

    @Test func unavailableContextClearsNumbersAndCanRecover() async throws {
        let rows = [try TestFixtures.transaction(amount: 10)]
        var initial = PlanFeature.State()
        initial.forecast = ForecastFeature.State()
        let store = TestStore(initialState: initial) { PlanFeature() } withDependencies: {
            $0.date.now = TestFixtures.date; $0.calendar = TestFixtures.calendar
        }
        var forecast = ForecastFeature.State()
        forecast.update(transactions: rows, date: TestFixtures.date, calendar: TestFixtures.calendar)
        await store.send(.transactionsUpdated(rows)) { $0.transactions = rows; $0.forecast = forecast }
        await store.send(.transactionsUpdated(nil)) { $0.transactions = nil; $0.forecast = ForecastFeature.State() }
        await store.send(.transactionsUpdated([])) {
            $0.transactions = []
            $0.forecast?.update(transactions: [], date: TestFixtures.date, calendar: TestFixtures.calendar)
        }
        #expect(store.state.forecast?.report?.currencies.isEmpty == true)
    }

    @Test func calculationFailureClearsOldReportAndRecovers() throws {
        var state = ForecastFeature.State()
        state.update(transactions: [], date: TestFixtures.date, calendar: TestFixtures.calendar)
        let large = Decimal.greatestFiniteMagnitude
        let previous = try #require(TestFixtures.calendar.date(byAdding: .month, value: -1, to: TestFixtures.date))
        state.update(transactions: [try TestFixtures.transaction(amount: large, date: previous)],
                     date: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(state.hasFailure)
        #expect(state.report == nil)
        state.update(transactions: [], date: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(state.hasFailure == false)
        #expect(state.report != nil)
    }

    @Test func foregroundRefreshRecalculatesAfterMonthRollover() async throws {
        var state = PlanFeature.State()
        state.forecast = ForecastFeature.State()
        state.transactions = []
        let later = try #require(TestFixtures.calendar.date(byAdding: .month, value: 1, to: TestFixtures.date))
        let store = TestStore(initialState: state) { PlanFeature() } withDependencies: {
            $0.date.now = later; $0.calendar = TestFixtures.calendar
            $0.goalsClient.load = { [] }; $0.budgetsClient.load = { [] }
        }
        await store.send(.task) {
            $0.isLoading = true
            $0.forecast?.update(transactions: [], date: later, calendar: TestFixtures.calendar)
        }
        await store.receive(.loaded([], [])) { $0.isLoading = false }
        #expect(store.state.forecast?.report?.month == TestFixtures.calendar.dateInterval(of: .month, for: later)?.start)
    }
}
