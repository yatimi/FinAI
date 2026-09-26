//
//  TransactionsView.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import SwiftUI

struct TransactionsView: View {
    let snapshot: FinanceSnapshot
    let select: (UUID) -> Void

    var body: some View {
        if snapshot.transactions.isEmpty {
            ContentUnavailableView("No transactions yet", systemImage: "list.bullet.rectangle", description: Text("Explore demo data from Overview to get started."))
        } else {
            List(snapshot.transactions) { transaction in
                Button { select(transaction.id) } label: {
                    TransactionRow(transaction: transaction)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .accessibilityIdentifier("transactionList")
        }
    }
}
