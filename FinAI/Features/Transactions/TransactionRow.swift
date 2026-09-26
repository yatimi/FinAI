//
//  TransactionRow.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text(transaction.merchant).font(.headline)
                    Spacer()
                    MoneyText(money: transaction.money)
                }
                VStack(alignment: .leading) {
                    Text(transaction.merchant).font(.headline)
                    MoneyText(money: transaction.money)
                }
            }
            Text(transaction.kind.title)
            Text(transaction.direction.title)
            Text(transaction.date, format: .dateTime.day().month().year())
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
