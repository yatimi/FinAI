//
//  SpendingBreakdownRow.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import SwiftUI

struct SpendingBreakdownRow: View {
    let title: Text
    let row: SpendingBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            title.font(.headline)
            MoneyMetricRow(title: .expenses, money: row.expenses)
            MoneyMetricRow(title: .refunds, money: row.refunds)
            MoneyMetricRow(title: .netSpending, money: row.netSpending)
        }
        .accessibilityElement(children: .combine)
    }
}
