//
//  MerchantRulesView.swift
//  FinAI
//
//  Created by Tommy on 02.10.26.
//

import ComposableArchitecture
import SwiftUI

struct MerchantRulesView: View {
    @Bindable var store: StoreOf<MerchantRulesFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Rules run locally before built-in suggestions. They apply to future previews only. Exact descriptions take priority, then the longest prefix. Transaction types, amounts and currencies stay unchanged.")
                        .font(.footnote)
                }
                if store.phase != .idle { ProgressView("Updating rules…") }
                if let failure = store.failure {
                    Section("Rules need attention") {
                        Text(failure.message)
                        if failure == .loading { Button("Try again") { store.send(.task) } }
                    }
                }
                if store.isEditorPresented {
                    Section(store.editingID == nil ? "New merchant rule" : "Edit merchant rule") {
                        TextField("Description to match", text: $store.pattern)
                            .submitLabel(.done)
                            .accessibilityIdentifier("rulePattern")
                        Picker("Match", selection: $store.matchMode) {
                            Text("Full description").tag(MerchantRule.MatchMode.exact)
                            Text("Description starts with").tag(MerchantRule.MatchMode.prefix)
                        }
                        Text("Matching ignores case, punctuation and spacing, and uses whole words. A short prefix can match many transactions; review every suggestion.")
                            .font(.footnote)
                        Picker("Transaction type", selection: $store.kind) {
                            ForEach(Transaction.Kind.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                        TextField("Merchant or payee", text: $store.merchant)
                            .submitLabel(.done)
                            .accessibilityIdentifier("ruleMerchant")
                        Picker("Category", selection: $store.category) {
                            ForEach(Category.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                        Button("Save rule") { store.send(.saveTapped) }
                            .accessibilityIdentifier("saveMerchantRule")
                        Button("Cancel editing", role: .cancel) { store.send(.cancelEditor) }
                    }
                } else {
                    Section {
                        Button("Add rule", systemImage: "plus") { store.send(.addTapped) }
                    }
                }
                Section("Saved merchant rules") {
                    if store.rules.isEmpty { Text("No merchant rules saved.") }
                    ForEach(store.rules) { rule in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(verbatim: rule.pattern).font(.headline)
                            Text(verbatim: rule.merchant)
                            Text(rule.category.title)
                            Text(rule.kind.title)
                            Text(rule.matchMode == .exact ? "Full description" : "Description starts with")
                                .font(.footnote).foregroundStyle(.secondary)
                            HStack {
                                Button("Edit rule") { store.send(.editTapped(rule.id)) }
                                Button("Delete rule", role: .destructive) { store.send(.deleteTapped(rule.id)) }
                            }.buttonStyle(.borderless)
                        }
                    }
                }
            }
            .disabled(store.phase != .idle)
            .navigationTitle("Merchant rules")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { store.send(.closeTapped) }.disabled(store.phase == .saving)
                }
            }
        }
        .interactiveDismissDisabled(store.phase == .saving)
        .alert($store.scope(state: \.alert, action: \.alert))
        .task { await store.send(.task).finish() }
    }
}

private extension MerchantRulesFeature.Failure {
    var message: LocalizedStringResource {
        switch self {
        case .loading: "Unable to load merchant rules. Try again before editing."
        case .saving: "Unable to save merchant rules. Please try again."
        case .invalid: "Enter a description with letters or numbers (up to 500 characters) and a merchant (up to 200 characters)."
        case .conflict: "A rule for this description, match mode and transaction type already exists. Edit that rule instead."
        case .missing: "This rule no longer exists. Close and reopen merchant rules."
        }
    }
}
