//
//  PlanProgressTests.swift
//  FinAITests
//
//  Created by Tommy on 19.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct PlanProgressTests {
    private let date = TestFixtures.date
    private let calendar = TestFixtures.calendar

    @Test func loadingUsesTransactionsThatArriveDuringTheRequest() async throws {
        let budget = CategoryBudget(id: UUID(), category: .groceries, limit: try Money(amount: 100, currency: .eur))
        let rows = [try transaction(amount: 25), try transaction(amount: 5, kind: .refund)]
        let progress = try BudgetPlanningService().progress(for: budget, transactions: rows, on: date, calendar: calendar)
        let clock = TestClock()
        let store = TestStore(initialState: PlanFeature.State()) { PlanFeature() } withDependencies: {
            $0.date.now = date
            $0.calendar = calendar
            $0.goalsClient.load = { [] }
            $0.budgetsClient.load = { try await clock.sleep(for: .seconds(1)); return [budget] }
        }
        await store.send(.task) { $0.isLoading = true }
        await store.send(.transactionsUpdated(rows)) { $0.transactions = rows }
        await clock.advance(by: .seconds(1))
        await store.receive(.loaded([], [budget])) {
            $0.isLoading = false; $0.budgets = [budget]; $0.budgetPlans = [budget.id: progress]
        }
        #expect(store.state.budgetPlans[budget.id]?.spent.amount == 20)
    }

    @Test func unavailableTransactionsNeverAppearAsZeroSpending() async throws {
        let budget = CategoryBudget(id: UUID(), category: .groceries, limit: try Money(amount: 100, currency: .eur))
        var state = PlanFeature.State()
        state.budgets = [budget]
        let rows = [try transaction(amount: 25, kind: .refund)]
        let progress = try BudgetPlanningService().progress(for: budget, transactions: rows, on: date, calendar: calendar)
        let store = TestStore(initialState: state) { PlanFeature() } withDependencies: {
            $0.date.now = date; $0.calendar = calendar
        }
        await store.send(.transactionsUpdated(nil))
        #expect(store.state.budgetPlans.isEmpty)
        await store.send(.transactionsUpdated(rows)) { $0.transactions = rows; $0.budgetPlans = [budget.id: progress] }
        #expect(store.state.budgetPlans[budget.id]?.spent.amount == -25)
        #expect(store.state.budgetPlans[budget.id]?.remaining.amount == 125)
        await store.send(.transactionsUpdated(nil)) { $0.transactions = nil; $0.budgetPlans = [:] }
    }

    @Test func overspendCurrenciesAndTransferExclusionUseExistingDomainSemantics() async throws {
        let eur = CategoryBudget(id: UUID(), category: .groceries, limit: try Money(amount: 100, currency: .eur))
        let usd = CategoryBudget(id: UUID(), category: .groceries, limit: try Money(amount: 50, currency: .usd))
        var state = PlanFeature.State()
        state.budgets = [eur, usd]
        let rows = [try transaction(amount: 120), try transaction(amount: 10, currency: .usd),
                    try transaction(amount: 500, kind: .transfer), try transaction(amount: 70, category: .shopping)]
        let plans = try Dictionary(uniqueKeysWithValues: [eur, usd].map {
            ($0.id, try BudgetPlanningService().progress(for: $0, transactions: rows, on: date, calendar: calendar))
        })
        let store = TestStore(initialState: state) { PlanFeature() } withDependencies: {
            $0.date.now = date; $0.calendar = calendar
        }
        await store.send(.transactionsUpdated(rows)) { $0.transactions = rows; $0.budgetPlans = plans }
        #expect(store.state.budgetPlans[eur.id]?.remaining.amount == -20)
        #expect(store.state.budgetPlans[eur.id]?.exceeded.amount == 20)
        #expect(store.state.budgetPlans[usd.id]?.remaining.amount == 40)
        let nextMonth = try #require(calendar.date(byAdding: .month, value: 1, to: date))
        let nextPlans = try Dictionary(uniqueKeysWithValues: [eur, usd].map {
            ($0.id, try BudgetPlanningService().progress(for: $0, transactions: rows, on: nextMonth, calendar: calendar))
        })
        store.dependencies.date.now = nextMonth
        await store.send(.transactionsUpdated(rows)) { $0.budgetPlans = nextPlans }
        #expect(store.state.budgetPlans[eur.id]?.spent.amount == 0)
        #expect(store.state.budgetPlans[usd.id]?.spent.amount == 0)
    }

    @Test func goalStatusesAreRecalculatedForTheCurrentDate() async throws {
        let goal = try makeGoal(saved: 250)
        let completed = try makeGoal(saved: 1100)
        var state = PlanFeature.State()
        state.goals = [goal, completed]
        let plans = try Dictionary(uniqueKeysWithValues: state.goals.map {
            ($0.id, try GoalPlanningService().plan(for: $0, on: date, calendar: calendar))
        })
        let store = TestStore(initialState: state) { PlanFeature() } withDependencies: {
            $0.date.now = date; $0.calendar = calendar
        }
        await store.send(.transactionsUpdated([])) { $0.transactions = []; $0.goalPlans = plans }
        #expect(store.state.goalPlans[goal.id]?.remaining.amount == 750)
        #expect(store.state.goalPlans[completed.id]?.status == .completed)
        let later = try #require(calendar.date(byAdding: .month, value: 2, to: date))
        let overdue = try GoalPlanningService().plan(for: goal, on: later, calendar: calendar)
        store.dependencies.date.now = later
        await store.send(.transactionsUpdated([])) { $0.goalPlans[goal.id] = overdue }
        #expect(store.state.goalPlans[goal.id]?.status == .overdue)
    }

    @Test func progressFailureClearsStaleNumbersAndRecoversAfterReload() async throws {
        let goal = try makeGoal(saved: 250)
        let plan = try GoalPlanningService().plan(for: goal, on: date, calendar: calendar)
        let invalid = SavingsGoal(id: goal.id, name: goal.name, target: goal.target,
                                 saved: try Money(amount: 250, currency: .usd), deadline: goal.deadline)
        var state = PlanFeature.State()
        state.goals = [invalid]
        state.goalPlans = [goal.id: plan]
        let store = TestStore(initialState: state) { PlanFeature() } withDependencies: {
            $0.date.now = date; $0.calendar = calendar
            $0.goalsClient.load = { [goal] }; $0.budgetsClient.load = { [] }
        }
        await store.send(.transactionsUpdated(nil)) { $0.goalPlans = [:]; $0.progressFailed = true }
        #expect(store.state.goals == [invalid])
        await store.send(.task) { $0.isLoading = true }
        await store.receive(.loaded([goal], [])) {
            $0.isLoading = false; $0.goals = [goal]; $0.goalPlans = [goal.id: plan]; $0.progressFailed = false
        }
    }

    @Test func cancelledLoadRejectsLateRecordUpdates() async throws {
        let goal = try makeGoal(saved: 250)
        let clock = TestClock()
        let store = TestStore(initialState: PlanFeature.State()) { PlanFeature() } withDependencies: {
            $0.goalsClient.load = { try await clock.sleep(for: .seconds(1)); return [goal] }
            $0.budgetsClient.load = { [] }
        }
        await store.send(.task) { $0.isLoading = true }
        await store.send(.cancelLoading) { $0.isLoading = false }
        await clock.advance(by: .seconds(1))
        await store.send(.loaded([goal], []))
        #expect(store.state.goals.isEmpty)
    }

    private func makeGoal(saved: Decimal) throws -> SavingsGoal {
        SavingsGoal(id: UUID(), name: "Laptop", target: try Money(amount: 1000, currency: .eur),
                    saved: try Money(amount: saved, currency: .eur),
                    deadline: try #require(calendar.date(byAdding: .month, value: 1, to: date)))
    }

    private func transaction(amount: Decimal, currency: Currency = .eur, kind: Transaction.Kind = .expense,
                             category: FinAI.Category = .groceries) throws -> Transaction {
        try Transaction(id: UUID(), accountID: UUID(), date: date, merchant: "Synthetic merchant",
                        rawDescription: "Synthetic description", money: Money(amount: amount, currency: currency),
                        direction: kind == .refund ? .credit : .debit, kind: kind, category: category, source: .demo)
    }
}
