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
                    Text(.matchingTransactions(results.count))
                }
            }
            ForEach(results) { transaction in
                Button { store.send(.transactionTapped(transaction.id)) } label: {
                    TransactionRow(transaction: transaction)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(.editTransaction, systemImage: AppSymbol.edit.rawValue) { store.send(.editTapped(transaction.id)) }
                        .tint(.blue)
                }
            }
        }
        .accessibilityIdentifier(AccessibilityID.transactionList)
        .overlay {
            if store.snapshot.transactions.isEmpty {
                ContentUnavailableView(.noTransactionsYet, systemImage: AppSymbol.transactions.rawValue, description: Text(.exploreDemoDataOrImportACsvFromOverviewToGetStarted))
            } else if results.isEmpty {
                ContentUnavailableView {
                    Label(.noMatchingTransactions, systemImage: AppSymbol.search.rawValue)
                } description: {
                    Text(store.hasInvalidDateRange
                         ? .theEndDateMustBeOnOrAfterTheStartDate
                         : .tryAnotherSearchOrResetYourFilters)
                }
            }
        }
        .searchable(text: $store.query.text, prompt: .merchantOrDescription)
        .autocorrectionDisabled()
        .safeAreaInset(edge: .top) {
            HStack {
                Button(.filters, systemImage: AppSymbol.filters.rawValue) {
                    store.send(.filtersTapped)
                }
                .accessibilityIdentifier(AccessibilityID.transactionFilters)
                Spacer()
                if store.query.isActive {
                    Button(.resetSearchAndFilters) { store.send(.resetTapped) }
                        .accessibilityIdentifier(AccessibilityID.resetTransactionFilters)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .sheet(isPresented: $store.isFilterPresented) { TransactionFiltersView(store: store) }
    }
}
