//
//  DebtsView.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import ComposableArchitecture
import SwiftUI

struct DebtsView: View {
    @Bindable var store: StoreOf<DebtsFeature>
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var repaymentFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                if store.phase != .idle { ProgressView(.updatingDebts) }
                if let failure = store.failure {
                    Section {
                        Text(failure.message).foregroundStyle(.red)
                        if failure == .loading {
                            Button(.tryAgain) { store.send(.task) }
                        }
                    }
                }
                if let draft = store.draft {
                    DebtEditorSection(draft: Binding(get: { store.draft ?? draft },
                        set: { store.send(.binding(.set(\.draft, $0))) }), keyboardFocus: $repaymentFocused)
                    editorActions
                } else if let draft = store.repayment, let debt = store.expected {
                    RepaymentEditorSection(draft: Binding(get: { store.repayment ?? draft },
                        set: { store.send(.binding(.set(\.repayment, $0))) }),
                        debt: debt, progress: store.progress[debt.id], keyboardFocus: $repaymentFocused)
                    editorActions
                } else {
                    Section { Button(.addDebt, systemImage: AppSymbol.add.rawValue) { store.send(.addTapped) }
                        .disabled(store.failure == .loading) }
                    Section(.savedDebts) {
                        if store.debts.isEmpty { Text(.noDebtsYet) }
                        ForEach(store.debts) { debt in
                            DisclosureGroup {
                                DebtRow(debt: debt, progress: store.progress[debt.id])
                                if store.progress[debt.id]?.status != .settled {
                                    Button(.recordDebtRepayment) { store.send(.repayTapped(debt.id)) }
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(verbatim: debt.person).font(.headline)
                                    Text(debt.direction == .iOwe ? .debtIOwe : .debtOwedToMe).font(.subheadline)
                                    if let progress = store.progress[debt.id] {
                                        DebtAmountRow(title: .debtRemaining, money: progress.remaining)
                                    }
                                }
                            }
                        }
                    }
                }
                Section { Text(.debtExplanation).font(.footnote) }
            }
            // Opening an editor from a long history must start at the top of its own form.
            .id(store.draft != nil ? "debt" : store.repayment != nil ? "repayment" : "list")
            .disabled(store.phase != .idle)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(.personalDebts)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(.done) { repaymentFocused = false }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(.close) { store.send(.closeTapped) }.disabled(store.phase == .saving)
                }
            }
        }
        .interactiveDismissDisabled(store.hasChanges || store.phase == .saving)
        .alert($store.scope(state: \.alert, action: \.alert))
        .task { await store.send(.task).finish() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { store.send(.task) } }
    }

    private var editorActions: some View {
        Section {
            Button(store.draft != nil ? .saveDebt : .saveDebtRepayment) { store.send(.saveTapped) }
                .disabled(!store.hasChanges)
            Button(.cancelEditing, role: .cancel) { store.send(.cancelEditor) }
        }
    }
}

private extension DebtsFeature.Failure {
    var message: LocalizedStringResource {
        switch self {
        case .loading: .debtsLoadFailure
        case .saving: .debtsSaveFailure
        case .invalid: .debtInvalidInput
        case .changed: .debtChangedFailure
        }
    }
}
