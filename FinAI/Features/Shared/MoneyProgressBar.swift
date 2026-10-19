//
//  MoneyProgressBar.swift
//  FinAI
//
//  Created by Tommy on 19.10.26.
//

import Foundation
import SwiftUI

/// Decorative geometry only; adjacent MoneyText values describe the exact amounts.
struct MoneyProgressBar: View {
    let value: Money
    let total: Money

    var body: some View {
        if value.currency == total.currency, total.amount > 0 {
            // Clamp only the drawing. Refunds and overspending remain exact in the accompanying text.
            ProgressView(value: NSDecimalNumber(decimal: min(max(value.amount, 0), total.amount)).doubleValue,
                         total: NSDecimalNumber(decimal: total.amount).doubleValue)
                .accessibilityHidden(true)
        }
    }
}
