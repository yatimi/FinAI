//
//  MoneyMetricCard.swift
//  FinAI
//
//  Created by Tommy on 07.10.26.
//

import SwiftUI

struct MoneyMetricCard: View {
    let title: LocalizedStringResource
    let money: Money

    var body: some View {
        FinanceCard {
            VStack(alignment: .leading, spacing: FinanceStyle.Spacing.compact) {
                Text(title)
                    .font(FinanceStyle.Typography.label)
                    .foregroundStyle(.secondary)
                MoneyText(money: money)
                    .font(FinanceStyle.Typography.amount)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    MoneyMetricCard(title: .netSpending, money: .zero(.eur))
        .padding()
        .background(FinanceStyle.Surface.canvas)
        .preferredColorScheme(.light)
}

#Preview("Dark · large text") {
    if let money = try? Money(amount: Decimal(-123456789) / 100, currency: .eur) {
        MoneyMetricCard(title: .netSpending, money: money)
            .padding()
            .background(FinanceStyle.Surface.canvas)
            .preferredColorScheme(.dark)
            .environment(\.dynamicTypeSize, .accessibility3)
    }
}
