//
//  WhatIfScenario.swift
//  FinAI
//
//  Created by Tommy on 23.10.26.
//

import Foundation

/// One unrecorded change to this month's forecast, never a transaction or saved plan.
struct WhatIfScenario: Equatable, Sendable {
    enum Change: String, CaseIterable, Sendable {
        case additionalExpense, additionalIncome, reducedExpenses, reducedIncome
    }
    enum ScenarioError: Error, Equatable {
        case invalidAmount, unavailableForecast, exceedsRemainingExpenses, exceedsRemainingIncome
    }

    let change: Change
    let money: Money
}
