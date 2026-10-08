//
//  TransactionEditView.swift
//  FinAI
//
//  Created by Tommy on 07.10.26.
//

import ComposableArchitecture
import SwiftUI

struct TransactionEditView: View {
    private enum Field: Hashable { case merchant, amount, currency }
    @FocusState private var focusedField: Field?
    @Bindable var store: StoreOf<TransactionEditFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(store.failure?.message ?? .transactionOriginalPreserved)
                        .font(.footnote)
                        .foregroundStyle(store.failure == nil ? Color.secondary : Color.red)
                        .accessibilityIdentifier(AccessibilityID.transactionEditError)
                }
                Section(.transaction) {
                    TextField(.merchantOrPayee, text: $store.draft.merchant)
                        .focused($focusedField, equals: .merchant)
                        .submitLabel(.done)
                        .accessibilityIdentifier(AccessibilityID.editTransactionMerchant)
                    DatePicker(.date, selection: $store.draft.date, displayedComponents: .date)
                    TextField(.transactionAmount, text: $store.draft.amount)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                        .accessibilityIdentifier(AccessibilityID.editTransactionAmount)
                    Text(.transactionAmountExplanation).font(.footnote).foregroundStyle(.secondary)
                    TextField(.currency, text: $store.draft.currencyCode)
                        .focused($focusedField, equals: .currency)
                        .submitLabel(.done)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier(AccessibilityID.editTransactionCurrency)
                    Picker(.account, selection: $store.draft.accountID) {
                        ForEach(store.accounts) { account in Text(verbatim: account.name).tag(account.id) }
                    }
                    Picker(.direction, selection: $store.draft.direction) {
                        Text(Transaction.Direction.debit.title).tag(Transaction.Direction.debit)
                        Text(Transaction.Direction.credit.title).tag(Transaction.Direction.credit)
                    }
                    Picker(.transactionType, selection: $store.draft.kind) {
                        ForEach(Transaction.Kind.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    Picker(.category, selection: $store.draft.category) {
                        ForEach(Category.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    if store.draft.kind == .income {
                        Picker(.incomeSource, selection: $store.draft.incomeKind) {
                            Text(.unspecifiedIncomeSource).tag(Optional<Transaction.IncomeKind>.none)
                            ForEach(Transaction.IncomeKind.allCases, id: \.self) { Text($0.title).tag(Optional($0)) }
                        }
                    }
                }
                Section(.originalDescription) {
                    Text(verbatim: store.expected.rawDescription)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onSubmit { focusedField = nil }
            .disabled(store.isSaving)
            .navigationTitle(.editTransaction)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(.done) { focusedField = nil }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(.cancel) { store.send(.cancelTapped) }.disabled(store.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if store.isSaving { ProgressView(.savingTransaction) }
                    else {
                        Button(.saveTransaction) { focusedField = nil; store.send(.saveTapped) }
                            .disabled(!store.hasChanges)
                            .accessibilityIdentifier(AccessibilityID.saveTransaction)
                    }
                }
            }
        }
        .interactiveDismissDisabled(store.hasChanges || store.isSaving)
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}
