//
//  PlanFeature.swift
//  FinAI
//
//  Created by Tommy on 10.10.26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct PlanFeature {
    private enum CancelID { case loading }

    @ObservableState
    struct State: Equatable {
        var goals: [SavingsGoal] = []
        var budgets: [CategoryBudget] = []
        var transactions: [Transaction]?
        var goalPlans: [UUID: GoalPlan] = [:]
        var budgetPlans: [UUID: BudgetProgress] = [:]
        var isLoading = false
        var loadFailed = false
        var progressFailed = false
    }

    enum Action: Equatable {
        case task
        case cancelLoading
        case transactionsUpdated([Transaction]?)
        case loaded([SavingsGoal], [CategoryBudget])
        case failed
    }

    @Dependency(\.goalsClient) var goalsClient
    @Dependency(\.budgetsClient) var budgetsClient
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.loadFailed = false
                updateProgress(&state)
                let goalsClient = goalsClient
                let budgetsClient = budgetsClient
                return .run { send in
                    do {
                        async let goals = goalsClient.load()
                        async let budgets = budgetsClient.load()
                        let result = try await (goals, budgets)
                        try Task.checkCancellation()
                        await send(.loaded(result.0, result.1))
                    } catch is CancellationError {
                        // The lifecycle action resets loading without displaying an error.
                    } catch { await send(.failed) }
                }.cancellable(id: CancelID.loading)
            case .cancelLoading:
                state.isLoading = false
                return .cancel(id: CancelID.loading)
            case let .transactionsUpdated(transactions):
                state.transactions = transactions
                updateProgress(&state)
                return .none
            case let .loaded(goals, budgets):
                guard state.isLoading else { return .none }
                state.isLoading = false
                state.goals = goals
                state.budgets = budgets
                state.loadFailed = false
                updateProgress(&state)
                return .none
            case .failed:
                guard state.isLoading else { return .none }
                state.isLoading = false
                state.loadFailed = true
                return .none
            }
        }
    }

    private func updateProgress(_ state: inout State) {
        guard !state.goals.isEmpty || !state.budgets.isEmpty else {
            state.goalPlans = [:]
            state.budgetPlans = [:]
            state.progressFailed = false
            return
        }
        let date = now
        let calendar = calendar
        do {
            var goals: [UUID: GoalPlan] = [:]
            for goal in state.goals {
                goals[goal.id] = try GoalPlanningService().plan(for: goal, on: date, calendar: calendar)
            }
            var budgets: [UUID: BudgetProgress] = [:]
            if let transactions = state.transactions {
                for budget in state.budgets {
                    budgets[budget.id] = try BudgetPlanningService().progress(
                        for: budget, transactions: transactions, on: date, calendar: calendar
                    )
                }
            }
            state.goalPlans = goals
            state.budgetPlans = budgets
            state.progressFailed = false
        } catch {
            state.goalPlans = [:]
            state.budgetPlans = [:]
            state.progressFailed = true
        }
    }
}
