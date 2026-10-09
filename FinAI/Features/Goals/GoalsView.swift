//
//  GoalsView.swift
//  FinAI
//
//  Created by Tommy on 08.10.26.
//

import ComposableArchitecture
import SwiftUI

struct GoalsView: View {
    @Bindable var store: StoreOf<GoalsFeature>
    @FocusState private var focusedField: GoalEditorSection.Field?

    var body: some View {
        NavigationStack {
            Form {
                Section { Text(.goalPlanningExplanation).font(.footnote) }
                if store.phase != .idle { ProgressView(.updatingGoals) }
                if let failure = store.failure {
                    Section {
                        Text(failure.message).foregroundStyle(.red)
                        if failure == .loading { Button(.tryAgain) { store.send(.task) } }
                    }
                }
                if let draft = store.draft {
                    GoalEditorSection(draft: Binding(
                        get: { store.draft ?? draft },
                        set: { store.send(.binding(.set(\.draft, $0))) }
                    ), keyboardFocus: $focusedField)
                    Section {
                        Button(.saveGoal) { focusedField = nil; store.send(.saveTapped) }
                            .disabled(!store.hasChanges)
                            .accessibilityIdentifier(AccessibilityID.saveGoal)
                        Button(.cancelEditing, role: .cancel) { store.send(.cancelEditor) }
                    }
                } else {
                    Section { Button(.addGoal, systemImage: AppSymbol.add.rawValue) { store.send(.addTapped) }
                        .disabled(store.failure == .loading) }
                }
                Section(.savedGoals) {
                    if store.goals.isEmpty { Text(.noGoalsYet) }
                    ForEach(store.goals) { goal in
                        GoalRow(goal: goal, plan: store.plans[goal.id])
                        Button(.editGoal) { store.send(.editTapped(goal.id)) }
                            .disabled(store.draft != nil)
                    }
                }
            }
            .disabled(store.phase != .idle)
            .scrollDismissesKeyboard(.interactively)
            .onSubmit { focusedField = nil }
            .navigationTitle(.savingsGoals)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(.done) { focusedField = nil }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(.close) { store.send(.closeTapped) }.disabled(store.phase == .saving)
                }
            }
        }
        .interactiveDismissDisabled(store.hasChanges || store.phase == .saving)
        .alert($store.scope(state: \.alert, action: \.alert))
        .task { await store.send(.task).finish() }
    }
}

private extension GoalsFeature.Failure {
    var message: LocalizedStringResource {
        switch self {
        case .loading: .goalsLoadFailure
        case .saving: .goalsSaveFailure
        case .invalid: .goalInvalidInput
        case .changed: .goalChangedFailure
        }
    }
}
