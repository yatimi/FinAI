//
//  PlanFeatureTests.swift
//  FinAITests
//
//  Created by Tommy on 10.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct PlanFeatureTests {
    @Test func retriesFailedLoadAndKeepsSavedData() async throws {
        let goal = try SavingsGoal(id: UUID(), name: "Laptop", target: Money(amount: 1000, currency: .eur), saved: Money(amount: 100, currency: .eur), deadline: TestFixtures.date)
        var initial = PlanFeature.State()
        initial.goals = [goal]
        initial.goalPlans = [goal.id: try GoalPlanningService().plan(for: goal, on: TestFixtures.date, calendar: TestFixtures.calendar)]
        let store = TestStore(initialState: initial) { PlanFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.goalsClient.load = { throw ValidationError.invalidSnapshot }
            $0.budgetsClient.load = { [] }
        }
        await store.send(.task) { $0.isLoading = true }
        await store.receive(.failed) {
            $0.isLoading = false
            $0.loadFailed = true
        }
        store.dependencies.goalsClient.load = { [goal] }
        await store.send(.task) {
            $0.isLoading = true
            $0.loadFailed = false
        }
        await store.receive(.loaded([goal], [])) { $0.isLoading = false }
    }

    @Test func cancelsLoadingWithoutFailure() async {
        let clock = TestClock()
        let store = TestStore(initialState: PlanFeature.State()) { PlanFeature() } withDependencies: {
            $0.goalsClient.load = { try await clock.sleep(for: .seconds(10)); return [] }
            $0.budgetsClient.load = { [] }
        }
        await store.send(.task) { $0.isLoading = true }
        await store.send(.cancelLoading) { $0.isLoading = false }
        await store.finish()
        #expect(store.state.loadFailed == false)
    }

    @Test func directAddWaitsForSavedGoalsBeforeOpeningEditor() async {
        let store = TestStore(initialState: GoalsFeature.State(editorRequest: .add)) { GoalsFeature() } withDependencies: {
            $0.goalsClient.load = { [] }
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
        }
        await store.send(.task) { $0.phase = .loading }
        await store.receive(.loaded(.success([]))) {
            $0.phase = .idle
            $0.editorRequest = nil
        }
        await store.receive(.addTapped) {
            $0.draft = GoalDraft(deadline: TestFixtures.calendar.date(byAdding: .month, value: 3, to: TestFixtures.date) ?? TestFixtures.date)
            $0.initialDraft = $0.draft
        }
    }

    @Test func selectedBudgetOpensExactRecordAfterLoading() async throws {
        let budget = CategoryBudget(id: UUID(), category: .groceries, limit: try Money(amount: 500, currency: .eur))
        let progress = try BudgetPlanningService().progress(for: budget, transactions: [], on: TestFixtures.date, calendar: TestFixtures.calendar)
        let store = TestStore(initialState: BudgetsFeature.State(editorRequest: .edit(budget.id))) { BudgetsFeature() } withDependencies: {
            $0.budgetsClient.load = { [budget] }
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
        }
        await store.send(.task) { $0.phase = .loading }
        await store.receive(.loaded(.success([budget]))) {
            $0.phase = .idle
            $0.editorRequest = nil
            $0.budgets = [budget]
            $0.plans = [budget.id: progress]
        }
        await store.receive(.editTapped(budget.id)) {
            $0.expected = budget
            $0.draft = BudgetDraft(budget: budget, locale: $0.locale)
            $0.initialDraft = $0.draft
        }
    }

    @Test func dismissingGoalEditorRefreshesPlan() async {
        var initial = AppFeature.State()
        initial.selectedTab = .plan
        initial.goals = GoalsFeature.State()
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.goalsClient.load = { [] }
            $0.budgetsClient.load = { [] }
        }
        await store.send(.goals(.dismiss)) { $0.goals = nil }
        await store.receive(.plan(.task)) { $0.plan.isLoading = true }
        await store.receive(.plan(.loaded([], []))) { $0.plan.isLoading = false }
    }
}
