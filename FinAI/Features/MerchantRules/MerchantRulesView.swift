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
                    Text(.merchantRulesExplanation)
                        .font(.footnote)
                }
                if store.phase != .idle { ProgressView(.updatingRules) }
                if let failure = store.failure {
                    Section(.rulesNeedAttention) {
                        Text(failure.message)
                        if failure == .loading { Button(.tryAgain) { store.send(.task) } }
                    }
                }
                if store.isEditorPresented {
                    Section(store.editingID == nil ? .newMerchantRule : .editMerchantRule) {
                        TextField(.descriptionToMatch, text: $store.pattern)
                            .submitLabel(.done)
                            .accessibilityIdentifier(AccessibilityID.rulePattern)
                        Picker(.match, selection: $store.matchMode) {
                            Text(.fullDescription).tag(MerchantRule.MatchMode.exact)
                            Text(.descriptionStartsWith).tag(MerchantRule.MatchMode.prefix)
                        }
                        Text(.merchantRuleMatchingExplanation)
                            .font(.footnote)
                        Picker(.transactionType, selection: $store.kind) {
                            ForEach(Transaction.Kind.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                        TextField(.merchantOrPayee, text: $store.merchant)
                            .submitLabel(.done)
                            .accessibilityIdentifier(AccessibilityID.ruleMerchant)
                        Picker(.category, selection: $store.category) {
                            ForEach(Category.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                        Button(.saveRule) { store.send(.saveTapped) }
                            .accessibilityIdentifier(AccessibilityID.saveMerchantRule)
                        Button(.cancelEditing, role: .cancel) { store.send(.cancelEditor) }
                    }
                } else {
                    Section {
                        Button(.addRule, systemImage: AppSymbol.add.rawValue) { store.send(.addTapped) }
                    }
                }
                Section(.savedMerchantRules) {
                    if store.rules.isEmpty { Text(.noMerchantRulesSaved) }
                    ForEach(store.rules) { rule in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(verbatim: rule.pattern).font(.headline)
                            Text(verbatim: rule.merchant)
                            Text(rule.category.title)
                            Text(rule.kind.title)
                            Text(rule.matchMode == .exact ? .fullDescription : .descriptionStartsWith)
                                .font(.footnote).foregroundStyle(.secondary)
                            HStack {
                                Button(.editRule) { store.send(.editTapped(rule.id)) }
                                Button(.deleteRule, role: .destructive) { store.send(.deleteTapped(rule.id)) }
                            }.buttonStyle(.borderless)
                        }
                    }
                }
            }
            .disabled(store.phase != .idle)
            .navigationTitle(.merchantRules)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.close) { store.send(.closeTapped) }.disabled(store.phase == .saving)
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
        case .loading: .unableToLoadMerchantRulesTryAgainBeforeEditing
        case .saving: .unableToSaveMerchantRulesPleaseTryAgain
        case .invalid: .invalidMerchantRuleMessage
        case .conflict: .conflictingMerchantRuleMessage
        case .missing: .thisRuleNoLongerExistsCloseAndReopenMerchantRules
        }
    }
}
