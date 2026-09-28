//
//  TransactionsView.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import SwiftUI

struct TransactionsView: View {
    @Bindable var store: StoreOf<TransactionsFeature>

    var body: some View {
        let results = store.results
        List {
            if store.query.isActive && !results.isEmpty {
                Section {
                    Text("Matching transactions: \(results.count)")
                }
            }
            ForEach(results) { transaction in
                Button { store.send(.transactionTapped(transaction.id)) } label: {
                    TransactionRow(transaction: transaction)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityIdentifier("transactionList")
        .overlay {
            if store.snapshot.transactions.isEmpty {
                ContentUnavailableView("No transactions yet", systemImage: "list.bullet.rectangle", description: Text("Explore demo data or import a CSV from Overview to get started."))
            } else if results.isEmpty {
                ContentUnavailableView {
                    Label("No matching transactions", systemImage: "magnifyingglass")
                } description: {
                    Text(store.hasInvalidDateRange
                         ? "The end date must be on or after the start date."
                         : "Try another search or reset your filters.")
                }
            }
        }
        .searchable(text: $store.query.text, prompt: "Merchant or description")
        .autocorrectionDisabled()
        .safeAreaInset(edge: .top) {
            HStack {
                Button("Filters", systemImage: "line.3.horizontal.decrease.circle") {
                    store.send(.filtersTapped)
                }
                .accessibilityIdentifier("transactionFilters")
                Spacer()
                if store.query.isActive {
                    Button("Reset search and filters") { store.send(.resetTapped) }
                        .accessibilityIdentifier("resetTransactionFilters")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .sheet(isPresented: $store.isFilterPresented) { TransactionFiltersView(store: store) }
    }
}
