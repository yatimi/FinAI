//
//  PlanView.swift
//  FinAI
//
//  Created by Tommy on 10.10.26.
//

import ComposableArchitecture
import SwiftUI

struct PlanView: View {
    let store: StoreOf<PlanFeature>
    let openBudgets: () -> Void
    let openGoals: () -> Void

    let addBudget: () -> Void
    let addGoal: () -> Void
    let selectBudget: (UUID) -> Void
    let selectGoal: (UUID) -> Void

    var body: some View {
        List {
            if store.isLoading { ProgressView { Text(.updatingPlan) } }
            if store.loadFailed {
                Section {
                    FinanceErrorState(title: .plan, message: .planLoadFailure, retryTitle: .tryAgain) {
                        store.send(.task)
                    }
                }
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
                        MoneyMetricRow(title: budget.category.title, money: budget.limit)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            } header: { Text(.monthlyBudgets) }
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
                        VStack(alignment: .leading, spacing: FinanceStyle.Spacing.compact) {
                            Text(verbatim: goal.name).font(.headline)
                            MoneyMetricRow(title: .goalSavedAmount, money: goal.saved)
                            MoneyMetricRow(title: .goalTargetAmount, money: goal.target)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            } header: { Text(.savingsGoals) }
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
        .task { await store.send(.task).finish() }
        .onDisappear { store.send(.cancelLoading) }
    }
}
