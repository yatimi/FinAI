//
//  MonthForecast.swift
//  FinAI
//
//  Created by Tommy on 23.10.26.
//

import Foundation

struct MonthForecast: Equatable, Sendable {
    struct CurrencyForecast: Equatable, Sendable, Identifiable {
        let recorded: CurrencySummary
        /// Nil means no expense or income history exists in the preceding calendar month.
        let projection: Projection?
        var id: String { recorded.currency.code }
    }

    struct Projection: Equatable, Sendable {
        let remainingVariableExpenses: Money
        let remainingRecurringExpenses: Money
        let remainingIncome: Money
        let expenses: Money
        let income: Money
        let netSpending: Money
        let netFlow: Money
    }

    let month: Date
    let basisMonth: Date
    let throughDay: Date
    let remainingDays: Int
    let currencies: [CurrencyForecast]
}
