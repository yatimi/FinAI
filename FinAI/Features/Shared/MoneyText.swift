//
//  MoneyText.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import SwiftUI

struct MoneyText: View {
    let money: Money
    @Environment(\.locale) private var locale
    var body: some View {
        Text(money.amount, format: .currency(code: money.currency.code).locale(locale))
            .monospacedDigit()
    }
}
