//
//  SpendingTransactionsView.swift
//  FinAI
//
//  Created by Tommy on 16.10.26.
//

import ComposableArchitecture
import SwiftUI

struct SpendingTransactionsView: View {
    let store: StoreOf<AnalyticsFeature>

    var body: some View {
        List {
            if let drilldown = store.drilldown {
                Section {
                    Text(drilldown.month, format: .dateTime.month(.wide).year())
                    Text(verbatim: drilldown.currency.code)
                    switch drilldown.group {
                    case let .category(category): Text(category.title)
                    case let .merchant(merchant):
                        if merchant.isEmpty { Text(.unknownMerchant) }
                        else { Text(verbatim: merchant) }
                    case nil: Text(.netSpending)
                    }
                    Text(.spendingDrilldownExplanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(store.drilldownTransactions) { transaction in
                Button { store.send(.transactionTapped(transaction.id)) } label: {
                    TransactionRow(transaction: transaction).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .overlay {
            if store.drilldownTransactions.isEmpty {
                ContentUnavailableView(.noMatchingTransactions, systemImage: AppSymbol.search.rawValue)
            }
        }
        .navigationTitle(.transactions)
    }
}
