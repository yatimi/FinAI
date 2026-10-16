//
//  AnalyticsFeatureTests.swift
//  FinAI
//
//  Created by Tommy on 16.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct AnalyticsFeatureTests {
    @Test func monthNavigationAndResetUseMonthStarts() async throws {
        var state = AnalyticsFeature.State()
        let calendar = TestFixtures.calendar
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 31)))
        state.update(snapshot: .empty, date: date, calendar: calendar)
        let currentDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let store = TestStore(initialState: state) { AnalyticsFeature() } withDependencies: {
            $0.date.now = currentDate
        }
        let february = try #require(calendar.date(from: DateComponents(year: 2026, month: 2, day: 1)))
        await store.send(.moveMonth(-1)) {
            $0.selectedMonth = february
            $0.recalculate()
        }
        #expect(store.state.report?.month == february)
        await store.send(.currentMonthTapped) {
            $0.referenceDate = currentDate
            $0.selectedMonth = nil
            $0.recalculate()
        }
        #expect(store.state.report?.month == calendar.dateInterval(of: .month, for: currentDate)?.start)
    }

    @Test func refreshRetainsHistoricalPeriodAndDrilldownReflectsCorrections() async throws {
        let calendar = TestFixtures.calendar
        let previous = try #require(calendar.date(byAdding: .month, value: -1, to: TestFixtures.date))
        var state = AnalyticsFeature.State()
        state.selectedMonth = previous
        let expense = try TestFixtures.transaction(amount: 10, date: previous)
        state.update(snapshot: FinanceSnapshot(accounts: [], transactions: [expense]), date: TestFixtures.date, calendar: calendar)
        let store = TestStore(initialState: state) { AnalyticsFeature() }
        let month = try #require(state.report?.month)
        await store.send(.spendingTapped(.eur, .merchant(expense.merchant))) {
            $0.drilldown = SpendingDrilldown(month: month, currency: .eur, group: .merchant(expense.merchant))
            $0.isDrilldownPresented = true
        }
        #expect(store.state.drilldownTransactions == [expense])
        var refreshed = store.state
        refreshed.update(snapshot: .empty, date: TestFixtures.date, calendar: calendar)
        #expect(refreshed.selectedMonth == previous)
        #expect(refreshed.drilldownTransactions.isEmpty)
    }

    @Test func arithmeticFailureClearsStaleReportAndCanRecover() throws {
        var state = AnalyticsFeature.State()
        let huge = try TestFixtures.transaction(amount: Decimal.greatestFiniteMagnitude)
        state.update(snapshot: FinanceSnapshot(accounts: [], transactions: [huge, huge]), date: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(state.hasFailure)
        #expect(state.report == nil)
        state.update(snapshot: .empty, date: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(state.hasFailure == false)
        #expect(state.report?.currencies.isEmpty == true)
    }

    @Test func rootDrilldownPreservesMainSearchAndOpensExistingDetails() async throws {
        let date = TestFixtures.date
        let calendar = TestFixtures.calendar
        let snapshot = try DemoData().make(referenceDate: date, calendar: calendar)
        let overview = try FinanceOverview.make(snapshot: snapshot, date: date, calendar: calendar)
        var state = AppFeature.State()
        state.overview = overview
        state.transactions.query.text = "Existing search"
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.date.now = date
            $0.calendar = calendar
        }
        await store.send(.analyticsOpened) {
            $0.analytics.update(snapshot: snapshot, date: date, calendar: calendar)
        }
        let expense = try #require(snapshot.transactions.first { $0.kind == .expense })
        let account = try #require(snapshot.accounts.first { $0.id == expense.accountID })
        await store.send(.analytics(.transactionTapped(expense.id))) {
            $0.detail = TransactionDetailFeature.State(transaction: expense, accountName: account.name,
                                                       accounts: snapshot.accounts, original: snapshot.originals[expense.id])
        }
        #expect(store.state.transactions.query.text == "Existing search")
    }

    @Test func openingDuringInitialLoadReceivesTheLoadedSnapshot() async throws {
        var state = AppFeature.State()
        state.isLoading = true
        let date = TestFixtures.date
        let calendar = TestFixtures.calendar
        let overview = try FinanceOverview.make(snapshot: .empty, date: date, calendar: calendar)
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.date.now = date
            $0.calendar = calendar
        }
        await store.send(.analyticsOpened) { $0.analytics.hasBeenOpened = true }
        await store.send(.response(.success(overview))) {
            $0.isLoading = false
            $0.overview = overview
            $0.analytics.update(snapshot: overview.snapshot, date: date, calendar: calendar)
            $0.transactions.update(snapshot: overview.snapshot, date: date, calendar: calendar)
        }
        #expect(store.state.analytics.report != nil)
    }

    @Test func openingAfterLoadFailureCanRetryWithoutShowingEmptyFinancialResults() async throws {
        var state = AppFeature.State()
        state.failure = .loading
        let date = TestFixtures.date
        let calendar = TestFixtures.calendar
        let overview = try FinanceOverview.make(snapshot: .empty, date: date, calendar: calendar)
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.date.now = date
            $0.calendar = calendar
            $0.financeClient.load = { _, _ in overview }
        }
        await store.send(.analyticsOpened) {
            $0.analytics.hasBeenOpened = true
            $0.analytics.hasFailure = true
        }
        #expect(store.state.analytics.report == nil)
        await store.send(.analytics(.retryTapped))
        await store.receive(.refresh) {
            $0.isLoading = true
            $0.failure = nil
        }
        await store.receive(.response(.success(overview))) {
            $0.isLoading = false
            $0.overview = overview
            $0.analytics.update(snapshot: overview.snapshot, date: date, calendar: calendar)
            $0.transactions.update(snapshot: overview.snapshot, date: date, calendar: calendar)
        }
    }
}
