//
//  CurrencySummary.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct CurrencySummary: Identifiable, Equatable, Sendable {
    let currency: Currency
    var income: Money
    var expenses: Money
    var refunds: Money
    let netSpending: Money
    let netFlow: Money
    var id: String { currency.code }
}
