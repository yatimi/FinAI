//
//  TransactionFiltersView.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import ComposableArchitecture
import SwiftUI

struct TransactionFiltersView: View {
    @Bindable var store: StoreOf<TransactionsFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section("Period") {
                    Picker("Period", selection: $store.query.period) {
                        Text("All dates").tag(TransactionQuery.Period.all)
                        Text("This month").tag(TransactionQuery.Period.thisMonth)
                        Text("Last month").tag(TransactionQuery.Period.lastMonth)
                        Text("Custom dates").tag(TransactionQuery.Period.custom)
                    }
                    if store.query.period == .custom {
                        DatePicker("From", selection: $store.query.startDate, displayedComponents: .date)
                        DatePicker("Through", selection: $store.query.endDate, displayedComponents: .date)
                        if store.hasInvalidDateRange {
                            Text("The end date must be on or after the start date.")
                                .foregroundStyle(.red)
                        }
                    }
                }
                Section("Transaction filters") {
                    Picker("Account", selection: $store.query.accountID) {
                        Text("All accounts").tag(Optional<UUID>.none)
                        ForEach(store.snapshot.accounts) { account in
                            Text(account.name).tag(Optional(account.id))
                        }
                    }
                    Picker("Category", selection: $store.query.category) {
                        Text("All categories").tag(Optional<Category>.none)
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.title).tag(Optional(category))
                        }
                    }
                    Picker("Transaction type", selection: $store.query.kind) {
                        Text("All types").tag(Optional<Transaction.Kind>.none)
                        ForEach(Transaction.Kind.allCases, id: \.self) { kind in
                            Text(kind.title).tag(Optional(kind))
                        }
                    }
                    Picker("Currency", selection: $store.query.currency) {
                        Text("All currencies").tag(Optional<Currency>.none)
                        ForEach(store.currencies) { currency in
                            Text(currency.code).tag(Optional(currency))
                        }
                    }
                }
                Section {
                    Button("Reset search and filters") { store.send(.resetTapped) }
                        .disabled(!store.query.isActive)
                } footer: {
                    Text("Filters apply together. Custom dates include both the first and last day.")
                }
            }
            .pickerStyle(.navigationLink)
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { store.isFilterPresented = false }
                }
            }
        }
    }
}
