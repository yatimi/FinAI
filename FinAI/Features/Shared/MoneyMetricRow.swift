//
//  MoneyMetricRow.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import SwiftUI

struct MoneyMetricRow: View {
    let title: LocalizedStringResource
    let money: Money

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack { Text(title); Spacer(); MoneyText(money: money) }
            VStack(alignment: .leading) { Text(title); MoneyText(money: money) }
        }
        .accessibilityElement(children: .combine)
    }
}
