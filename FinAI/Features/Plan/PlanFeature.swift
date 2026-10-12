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
        var isLoading = false
        var loadFailed = false
    }

    enum Action: Equatable {
        case task
        case cancelLoading
        case loaded([SavingsGoal], [CategoryBudget])
        case failed
    }

    @Dependency(\.goalsClient) var goalsClient
    @Dependency(\.budgetsClient) var budgetsClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.loadFailed = false
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
            case let .loaded(goals, budgets):
                state.isLoading = false
                state.goals = goals
                state.budgets = budgets
                state.loadFailed = false
                return .none
            case .failed:
                state.isLoading = false
                state.loadFailed = true
                return .none
            }
        }
    }
}
