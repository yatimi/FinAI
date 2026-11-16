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
        VStack(alignment: .leading, spacing: FinanceStyle.Spacing.tight) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: FinanceStyle.Spacing.standard) {
                    merchant
                    Spacer(minLength: FinanceStyle.Spacing.compact)
                    amount(alignment: .trailing)
                }
                VStack(alignment: .leading, spacing: FinanceStyle.Spacing.tight) {
                    merchant
                    amount(alignment: .leading)
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: FinanceStyle.Spacing.compact) {
                    kind
                    if showsCategory { Text(transaction.category.title) }
                    Spacer(minLength: FinanceStyle.Spacing.compact)
                    date
                }
                VStack(alignment: .leading, spacing: FinanceStyle.Spacing.tight) {
                    kind
                    if showsCategory { Text(transaction.category.title) }
                    date
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, FinanceStyle.Spacing.tight)
        .accessibilityElement(children: .combine)
    }

    private var merchant: some View {
        Group {
            if transaction.merchant.isEmpty { Text(.unknownMerchant) }
            else { Text(verbatim: transaction.merchant) }
        }
        .font(.headline)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func amount(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: FinanceStyle.Spacing.tight) {
            MoneyText(money: transaction.money).font(.body.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: FinanceStyle.Spacing.compact) {
                    Text(transaction.direction.title)
                    Text(verbatim: transaction.money.currency.code)
                }
                VStack(alignment: .leading) {
                    Text(transaction.direction.title)
                    Text(verbatim: transaction.money.currency.code)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private var kind: some View {
        Text(transaction.kind.title).fontWeight(.semibold)
    }

    private var showsCategory: Bool {
        switch (transaction.kind, transaction.category) {
        case (.income, .income), (.transfer, .transfers): false
        default: true
        }
    }

    private var date: some View {
        Text(transaction.date, format: .dateTime.day().month().year())
    }
}
