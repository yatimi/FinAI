//
//  TransactionDetailView.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import SwiftUI

struct TransactionDetailView: View {
    @Bindable var store: StoreOf<TransactionDetailFeature>
    var body: some View {
        NavigationStack {
            Form {
                Section(.transaction) {
                    Text(store.transaction.merchant).font(.headline)
                    MoneyText(money: store.transaction.money).font(.title2)
                    LabeledContent(.currency, value: store.transaction.money.currency.code)
                    LabeledContent(.transactionType) { Text(store.transaction.kind.title) }
                    if let incomeKind = store.transaction.incomeKind {
                        LabeledContent(.incomeSource) { Text(incomeKind.title) }
                    }
                    LabeledContent(.direction) { Text(store.transaction.direction.title) }
                    LabeledContent(.category) { Text(store.transaction.category.title) }
                    LabeledContent(.account, value: store.accountName)
                    LabeledContent(.date) {
                        Text(store.transaction.date, format: .dateTime.day().month().year())
                    }
                }
                if let original = store.original {
                    Section(.originalTransactionValues) {
                        MoneyText(money: original.money)
                        Text(original.date, format: .dateTime.day().month().year())
                        Text(original.direction.title)
                        if let account = store.accounts.first(where: { $0.id == original.accountID }) {
                            LabeledContent(.account, value: account.name)
                        }
                    }
                }
                Section(.originalDescription) { Text(store.transaction.rawDescription) }
                Section(.source) {
                    Text(store.transaction.source == .demo ? .syntheticDemoData : .importedData)
                }
            }
            .navigationTitle(.transactionDetails)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(.editTransaction) { store.send(.editTapped) }
                        .accessibilityIdentifier(AccessibilityID.editTransaction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.done) { store.send(.closeTapped) }
                }
            }
        }
        .interactiveDismissDisabled(store.editor != nil)
        .sheet(item: $store.scope(state: \.editor, action: \.editor)) { TransactionEditView(store: $0) }
    }
}
