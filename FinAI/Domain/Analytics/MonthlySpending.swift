//
//  MonthlySpending.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import Foundation

struct MonthlySpending: Identifiable, Equatable, Sendable {
    let currency: Currency
    let current: Money
    let previous: Money
    let change: Money
    /// A ratio for percent formatting; undefined for a zero or negative baseline.
    let changeRatio: Decimal?
    let categories: [SpendingBreakdown]
    let merchants: [SpendingBreakdown]
    var id: String { currency.code }
}
