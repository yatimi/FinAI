//
//  TransactionsFeatureTests.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct TransactionsFeatureTests {
    @Test func searchFiltersResetAndPresentation() async throws {
        let snapshot = try DemoData().make(referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        var state = TransactionsFeature.State()
        state.update(snapshot: snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        let store = TestStore(initialState: state) { TransactionsFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
        }
        await store.send(.binding(.set(\.query.text, "amazon"))) { $0.query.text = "amazon" }
        #expect(store.state.results.isEmpty == false)
        #expect(store.state.results.allSatisfy { $0.merchant == "Amazon" })
        await store.send(.filtersTapped) {
            $0.query.startDate = TestFixtures.date
            $0.query.endDate = TestFixtures.date
            $0.isFilterPresented = true
        }
        await store.send(.binding(.set(\.query.kind, .refund))) { $0.query.kind = .refund }
        #expect(store.state.results.allSatisfy { $0.kind == .refund })
        await store.send(.binding(.set(\.query.currency, .usd))) { $0.query.currency = .usd }
        #expect(store.state.results.isEmpty)
        await store.send(.resetTapped) { $0.query = TransactionQuery(startDate: TestFixtures.date, endDate: TestFixtures.date) }
        #expect(store.state.results == snapshot.transactions)
        #expect(store.state.query.isActive == false)
        await store.send(.binding(.set(\.isFilterPresented, false))) { $0.isFilterPresented = false }
    }

    @Test func refreshPreservesQueryAndUpdatesResultsAndNavigation() async throws {
        let snapshot = try DemoData().make(referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        let overview = try FinanceOverview.make(snapshot: snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        var state = AppFeature.State()
        state.transactions.query.text = "REWE"
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.financeClient.load = { _, _ in overview }
        }
        await store.send(.refresh) { $0.isLoading = true }
        await store.receive(.response(.success(overview))) {
            $0.isLoading = false
            $0.overview = overview
            $0.transactions.update(snapshot: snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        }
        let transaction = try #require(store.state.transactions.results.first)
        #expect(transaction.merchant == "REWE")
        let account = try #require(snapshot.accounts.first { $0.id == transaction.accountID })
        await store.send(.transactions(.transactionTapped(transaction.id))) {
            $0.detail = TransactionDetailFeature.State(transaction: transaction, accountName: account.name, accounts: snapshot.accounts, original: snapshot.originals[transaction.id])
        }
        await store.send(.detail(.dismiss)) { $0.detail = nil }
    }
}
