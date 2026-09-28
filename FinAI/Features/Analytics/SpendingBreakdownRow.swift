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
            MoneyMetricRow(title: "Expenses", money: row.expenses)
            MoneyMetricRow(title: "Refunds", money: row.refunds)
            MoneyMetricRow(title: "Net spending", money: row.netSpending)
        }
        .accessibilityElement(children: .combine)
    }
}
