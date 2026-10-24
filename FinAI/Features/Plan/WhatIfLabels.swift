//
//  WhatIfLabels.swift
//  FinAI
//
//  Created by Tommy on 23.10.26.
//

import Foundation

extension WhatIfScenario.Change {
    var title: LocalizedStringResource {
        switch self {
        case .additionalExpense: .whatIfAdditionalExpense
        case .additionalIncome: .whatIfAdditionalIncome
        case .reducedExpenses: .whatIfReducedExpenses
        case .reducedIncome: .whatIfReducedIncome
        }
    }
}

extension ForecastFeature.ScenarioFailure {
    var message: LocalizedStringResource {
        switch self {
        case .invalidAmount: .whatIfInvalidAmount
        case .unavailable: .whatIfNeedsForecast
        case .remainingExpenses: .whatIfExpenseReductionLimit
        case .remainingIncome: .whatIfIncomeReductionLimit
        case .calculation: .whatIfCalculationUnavailable
        }
    }
}
