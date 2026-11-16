//
//  AssistantTransactionsView.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import ComposableArchitecture
import SwiftUI

struct AssistantTransactionsView: View {
    let store: StoreOf<AssistantFeature>

    var body: some View {
        List {
            if let drilldown = store.drilldown {
                Section {
                    Text(drilldown.month, format: .dateTime.month(.wide).year())
                    Text(verbatim: drilldown.currency.code)
                    if case let .merchant(merchant) = drilldown.group { Text(verbatim: merchant) }
                    if case let .category(category) = drilldown.group { Text(category.title) }
                    if let excluded = drilldown.excludedMerchant {
                        Text(.assistantExcludedMerchant)
                        Text(verbatim: excluded)
                    }
                    Text(.spendingDrilldownExplanation).font(.footnote).foregroundStyle(.secondary)
                }
            }
            if store.drilldownTransactions.isEmpty {
                Text(.noMatchingTransactions)
            }
            ForEach(store.drilldownTransactions) { transaction in
                Button { store.send(.transactionTapped(transaction.id)) } label: {
                    TransactionRow(transaction: transaction).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(.transactions)
        .accessibilityIdentifier(AccessibilityID.assistantTransactions)
    }
}
