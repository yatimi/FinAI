//
//  AppFeatureTests.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct AppFeatureTests {
    @Test func loadsOverview() async throws {
        let overview = try FinanceOverview.make(snapshot: .empty, date: TestFixtures.date, calendar: TestFixtures.calendar)
        let store = TestStore(initialState: AppFeature.State()) { AppFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.financeClient.load = { _, _ in overview }
        }
        await store.send(.task) { $0.isLoading = true }
        await store.receive(.response(.success(overview))) {
            $0.isLoading = false
            $0.overview = overview
            $0.transactions.update(snapshot: overview.snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        }
        await store.send(.task)
    }

    @Test func loadFailureCanBeRetried() async throws {
        let store = TestStore(initialState: AppFeature.State()) { AppFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.financeClient.load = { _, _ in throw ValidationError.invalidSnapshot }
        }
        await store.send(.task) { $0.isLoading = true }
        await store.receive(.response(.failure(.loading))) {
            $0.isLoading = false
            $0.failure = .loading
        }
        let overview = try FinanceOverview.make(snapshot: .empty, date: TestFixtures.date, calendar: TestFixtures.calendar)
        store.dependencies.financeClient.load = { _, _ in overview }
        await store.send(.refresh) {
            $0.isLoading = true
            $0.failure = nil
        }
        await store.receive(.response(.success(overview))) {
            $0.isLoading = false
            $0.overview = overview
            $0.transactions.update(snapshot: overview.snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        }
    }

    @Test func demoRequiresConfirmation() async throws {
        let empty = try FinanceOverview.make(snapshot: .empty, date: TestFixtures.date, calendar: TestFixtures.calendar)
        let demo = try FinanceOverview.make(
            snapshot: DemoData().make(referenceDate: TestFixtures.date, calendar: TestFixtures.calendar),
            date: TestFixtures.date, calendar: TestFixtures.calendar
        )
        var state = AppFeature.State()
        state.overview = empty
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.financeClient.addDemo = { _, _ in demo }
        }
        await store.send(.demoTapped) {
            $0.alert = AlertState {
                TextState("Explore with demo data?")
            } actions: {
                ButtonState(action: .confirmDemo) { TextState("Load demo data") }
                ButtonState(role: .cancel) { TextState("Cancel") }
            } message: {
                TextState("Synthetic accounts and transactions will be saved on this device. No bank connection is needed.")
            }
        }
        await store.send(.alert(.presented(.confirmDemo))) {
            $0.alert = nil
            $0.isLoading = true
        }
        await store.receive(.response(.success(demo))) {
            $0.isLoading = false
            $0.overview = demo
            $0.transactions.update(snapshot: demo.snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        }
        await store.send(.demoTapped)
    }

    @Test func cancelsInFlightLoadWithoutFailure() async throws {
        let clock = TestClock()
        let store = TestStore(initialState: AppFeature.State()) { AppFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.financeClient.load = { _, _ in
                try await clock.sleep(for: .seconds(10))
                return try FinanceOverview.make(snapshot: .empty, date: TestFixtures.date, calendar: TestFixtures.calendar)
            }
        }
        await store.send(.task) { $0.isLoading = true }
        await store.send(.cancelLoading) { $0.isLoading = false }
        await store.finish()
        #expect(store.state.failure == nil)
    }

    @Test func navigationShowsSelectedTransactionAndDismisses() async throws {
        let snapshot = try DemoData().make(referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        let transaction = try #require(snapshot.transactions.first)
        let account = try #require(snapshot.accounts.first { $0.id == transaction.accountID })
        var state = AppFeature.State()
        state.overview = try FinanceOverview.make(snapshot: snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        let store = TestStore(initialState: state) { AppFeature() }
        await store.send(.binding(.set(\.selectedTab, .transactions))) { $0.selectedTab = .transactions }
        await store.send(.transactions(.transactionTapped(transaction.id))) {
            $0.detail = TransactionDetailFeature.State(transaction: transaction, accountName: account.name)
        }
        await store.send(.detail(.dismiss)) { $0.detail = nil }
    }
}
