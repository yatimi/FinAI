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
                Section("Transaction") {
                    Text(store.transaction.merchant).font(.headline)
                    MoneyText(money: store.transaction.money).font(.title2)
                    LabeledContent("Currency", value: store.transaction.money.currency.code)
                    LabeledContent("Transaction type") { Text(store.transaction.kind.title) }
                    LabeledContent("Direction") { Text(store.transaction.direction.title) }
                    LabeledContent("Category") { Text(store.transaction.category.title) }
                    LabeledContent("Account", value: store.accountName)
                    LabeledContent("Date") {
                        Text(store.transaction.date, format: .dateTime.day().month().year())
                    }
                }
                Section("Original description") { Text(store.transaction.rawDescription) }
                Section("Source") {
                    Text(store.transaction.source == .demo ? "Synthetic demo data" : "Imported data")
                }
            }
            .navigationTitle("Transaction details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { store.send(.closeTapped) }
                }
            }
        }
    }
}
