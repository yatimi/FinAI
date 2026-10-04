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
                Section(.period) {
                    Picker(.period, selection: $store.query.period) {
                        Text(.allDates).tag(TransactionQuery.Period.all)
                        Text(.thisMonth).tag(TransactionQuery.Period.thisMonth)
                        Text(.lastMonth).tag(TransactionQuery.Period.lastMonth)
                        Text(.customDates).tag(TransactionQuery.Period.custom)
                    }
                    if store.query.period == .custom {
                        DatePicker(.from, selection: $store.query.startDate, displayedComponents: .date)
                        DatePicker(.through, selection: $store.query.endDate, displayedComponents: .date)
                        if store.hasInvalidDateRange {
                            Text(.theEndDateMustBeOnOrAfterTheStartDate)
                                .foregroundStyle(.red)
                        }
                    }
                }
                Section(.transactionFilters) {
                    Picker(.account, selection: $store.query.accountID) {
                        Text(.allAccounts).tag(Optional<UUID>.none)
                        ForEach(store.snapshot.accounts) { account in
                            Text(account.name).tag(Optional(account.id))
                        }
                    }
                    Picker(.category, selection: $store.query.category) {
                        Text(.allCategories).tag(Optional<Category>.none)
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.title).tag(Optional(category))
                        }
                    }
                    Picker(.transactionType, selection: $store.query.kind) {
                        Text(.allTypes).tag(Optional<Transaction.Kind>.none)
                        ForEach(Transaction.Kind.allCases, id: \.self) { kind in
                            Text(kind.title).tag(Optional(kind))
                        }
                    }
                    Picker(.currency, selection: $store.query.currency) {
                        Text(.allCurrencies).tag(Optional<Currency>.none)
                        ForEach(store.currencies) { currency in
                            Text(currency.code).tag(Optional(currency))
                        }
                    }
                }
                Section {
                    Button(.resetSearchAndFilters) { store.send(.resetTapped) }
                        .disabled(!store.query.isActive)
                } footer: {
                    Text(.transactionFiltersExplanation)
                }
            }
            .pickerStyle(.navigationLink)
            .navigationTitle(.filters)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.done) { store.isFilterPresented = false }
                }
            }
        }
    }
}
