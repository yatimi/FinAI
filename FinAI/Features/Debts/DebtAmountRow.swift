//
//  DebtAmountRow.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import SwiftUI

/// Keeps long debt labels readable at accessibility text sizes inside disclosure rows.
struct DebtAmountRow: View {
    let title: LocalizedStringResource
    let money: Money
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading) {
                Text(title).fixedSize(horizontal: false, vertical: true)
                MoneyText(money: money).fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        } else {
            MoneyMetricRow(title: title, money: money)
        }
    }
}
