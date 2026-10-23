//
//  PlanView.swift
//  FinAI
//
//  Created by Tommy on 10.10.26.
//

import ComposableArchitecture
import SwiftUI

struct PlanView: View {
    @Bindable var store: StoreOf<PlanFeature>
    let transactions: [Transaction]?
    @Environment(\.scenePhase) private var scenePhase
    let openBudgets: () -> Void
    let openGoals: () -> Void

    let addBudget: () -> Void
    let addGoal: () -> Void
    let selectBudget: (UUID) -> Void
    let selectGoal: (UUID) -> Void

    var body: some View {
        List {
            Section {
                Button { store.send(.forecastTapped) } label: {
                    Label(.monthEndForecast, systemImage: AppSymbol.overview.rawValue)
                }
                .accessibilityIdentifier(AccessibilityID.openMonthForecast)
            }
            if store.isLoading { ProgressView { Text(.updatingPlan) } }
            if store.loadFailed {
                Section {
                    FinanceErrorState(title: .plan, message: .planLoadFailure, retryTitle: .tryAgain) {
                        store.send(.task)
                    }
                }
            }
            if store.progressFailed {
                Section { Text(.planProgressUnavailable).foregroundStyle(.secondary) }
            }
            Section {
                Button(action: openBudgets) {
                    Label(.budgets, systemImage: AppSymbol.analytics.rawValue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                    .accessibilityIdentifier(AccessibilityID.openBudgets)
                if store.budgets.isEmpty && !store.isLoading && !store.loadFailed {
                    Text(.noBudgetsYet).foregroundStyle(.secondary)
                }
                ForEach(store.budgets) { budget in
                    Button { selectBudget(budget.id) } label: {
                        PlanBudgetSummary(budget: budget, progress: store.budgetPlans[budget.id])
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            } header: { Text(.monthlyBudgets) } footer: {
                if !store.budgets.isEmpty { Text(.planBudgetSummaryExplanation) }
            }
            Section {
                Button(action: openGoals) {
                    Label(.savingsGoals, systemImage: AppSymbol.goals.rawValue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                    .accessibilityIdentifier(AccessibilityID.openGoals)
                if store.goals.isEmpty && !store.isLoading && !store.loadFailed {
                    Text(.noGoalsYet).foregroundStyle(.secondary)
                }
                ForEach(store.goals) { goal in
                    Button { selectGoal(goal.id) } label: {
                        PlanGoalSummary(goal: goal, plan: store.goalPlans[goal.id])
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            } header: { Text(.savingsGoals) } footer: {
                if !store.goals.isEmpty { Text(.planGoalSummaryExplanation) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(FinanceStyle.Surface.canvas)
        .navigationTitle(Text(.plan))
        .toolbar {
            Menu {
                Button(.addBudget, systemImage: AppSymbol.analytics.rawValue, action: addBudget)
                Button(.addGoal, systemImage: AppSymbol.goals.rawValue, action: addGoal)
            } label: { Label(.addToPlan, systemImage: AppSymbol.add.rawValue) }
        }
        .sheet(item: $store.scope(state: \.forecast, action: \.forecast)) { forecastStore in
            ForecastView(store: forecastStore)
        }
        .task {
            store.send(.transactionsUpdated(transactions))
            await store.send(.task).finish()
        }
        .onChange(of: transactions) { _, transactions in
            store.send(.transactionsUpdated(transactions))
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.task) }
        }
        .onDisappear { store.send(.cancelLoading) }
    }
}
