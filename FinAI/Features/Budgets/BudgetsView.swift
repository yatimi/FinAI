//
//  BudgetsView.swift
//  FinAI
//
//  Created by Tommy on 09.10.26.
//

import ComposableArchitecture
import SwiftUI

struct BudgetsView: View {
    @Bindable var store: StoreOf<BudgetsFeature>
    @FocusState private var focusedField: BudgetEditorSection.Field?

    var body: some View {
        NavigationStack {
            Form {
                Section { Text(.budgetPlanningExplanation).font(.footnote) }
                if store.phase != .idle { ProgressView(.updatingBudgets) }
                if let failure = store.failure {
                    Section {
                        Text(failure.message).foregroundStyle(.red)
                        if failure == .loading { Button(.tryAgain) { store.send(.task) } }
                    }
                }
                if let draft = store.draft {
                    BudgetEditorSection(draft: Binding(
                        get: { store.draft ?? draft },
                        set: { store.send(.binding(.set(\.draft, $0))) }
                    ), keyboardFocus: $focusedField)
                    Section {
                        Button(.saveBudget) { focusedField = nil; store.send(.saveTapped) }
                            .disabled(!store.hasChanges)
                            .accessibilityIdentifier(AccessibilityID.saveBudget)
                        Button(.cancelEditing, role: .cancel) { store.send(.cancelEditor) }
                    }
                } else {
                    Section { Button(.addBudget, systemImage: AppSymbol.add.rawValue) { store.send(.addTapped) }
                        .disabled(store.failure == .loading) }
                }
                Section(.savedBudgets) {
                    if store.budgets.isEmpty { Text(.noBudgetsYet) }
                    ForEach(store.budgets) { budget in
                        BudgetRow(budget: budget, progress: store.plans[budget.id])
                        Button(.editBudget) { store.send(.editTapped(budget.id)) }
                            .disabled(store.draft != nil)
                    }
                }
            }
            .disabled(store.phase != .idle)
            .scrollDismissesKeyboard(.interactively)
            .onSubmit { focusedField = nil }
            .navigationTitle(.budgets)
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

private extension BudgetsFeature.Failure {
    var message: LocalizedStringResource {
        switch self {
        case .loading: .budgetsLoadFailure
        case .saving: .budgetsSaveFailure
        case .invalid: .budgetInvalidInput
        case .changed: .budgetChangedFailure
        case .duplicate: .budgetDuplicateFailure
        }
    }
}
