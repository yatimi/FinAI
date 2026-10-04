//
//  TransactionDetailView.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import SwiftUI

struct TransactionDetailView: View {
    let store: StoreOf<TransactionDetailFeature>
    var body: some View {
        NavigationStack {
            Form {
                Section(.transaction) {
                    Text(store.transaction.merchant).font(.headline)
                    MoneyText(money: store.transaction.money).font(.title2)
                    LabeledContent(.currency, value: store.transaction.money.currency.code)
                    LabeledContent(.transactionType) { Text(store.transaction.kind.title) }
                    LabeledContent(.direction) { Text(store.transaction.direction.title) }
                    LabeledContent(.category) { Text(store.transaction.category.title) }
                    LabeledContent(.account, value: store.accountName)
                    LabeledContent(.date) {
                        Text(store.transaction.date, format: .dateTime.day().month().year())
                    }
                }
                Section(.originalDescription) { Text(store.transaction.rawDescription) }
                Section(.source) {
                    Text(store.transaction.source == .demo ? .syntheticDemoData : .importedData)
                }
            }
            .navigationTitle(.transactionDetails)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.done) { store.send(.closeTapped) }
                }
            }
        }
    }
}
