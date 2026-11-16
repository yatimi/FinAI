//
//  BudgetNavigationTests.swift
//  FinAITests
//
//  Created by Tommy on 09.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct BudgetNavigationTests {
    @Test func opensWithCurrentTransactionsAndRefreshesPresentedBudgets() async throws {
        let snapshot = try DemoData().make(referenceDate: TestFixtures.date, calendar: TestFixtures.calendar)
        let overview = try FinanceOverview.make(snapshot: snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        var initial = AppFeature.State()
        initial.overview = overview
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.financeClient.load = { _, _ in overview }
        }
        await store.send(.budgetsTapped) {
            $0.budgets = BudgetsFeature.State(transactions: snapshot.transactions)
        }
        await store.send(.refresh) { $0.isLoading = true }
        await store.receive(.response(.success(overview))) {
            $0.isLoading = false
            $0.transactions.update(snapshot: snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        }
        await store.receive(.budgets(.presented(.transactionsUpdated(snapshot.transactions))))
    }
}
