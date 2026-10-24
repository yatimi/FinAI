//
//  WhatIfPlanningService.swift
//  FinAI
//
//  Created by Tommy on 23.10.26.
//

import Foundation

struct WhatIfPlanningService: Sendable {
    func simulate(_ scenario: WhatIfScenario, forecast: MonthForecast) throws -> WhatIfResult {
        guard scenario.money.amount > 0 else { throw WhatIfScenario.ScenarioError.invalidAmount }
        guard let currency = forecast.currencies.first(where: { $0.recorded.currency == scenario.money.currency }),
              let baseline = currency.projection else { throw WhatIfScenario.ScenarioError.unavailableForecast }
        var expenses = baseline.expenses
        var income = baseline.income
        switch scenario.change {
        case .additionalExpense:
            expenses = try expenses.adding(scenario.money)
        case .additionalIncome:
            income = try income.adding(scenario.money)
        case .reducedExpenses:
            let remaining = try baseline.remainingVariableExpenses.adding(baseline.remainingRecurringExpenses)
            guard scenario.money.amount <= remaining.amount else {
                throw WhatIfScenario.ScenarioError.exceedsRemainingExpenses
            }
            expenses = try expenses.subtracting(scenario.money)
        case .reducedIncome:
            guard scenario.money.amount <= baseline.remainingIncome.amount else {
                throw WhatIfScenario.ScenarioError.exceedsRemainingIncome
            }
            income = try income.subtracting(scenario.money)
        }
        let spending = try expenses.subtracting(currency.recorded.refunds)
        let flow = try income.subtracting(spending)
        return try WhatIfResult(scenario: scenario, baseline: baseline, expenses: expenses, income: income,
                               netSpending: spending, netFlow: flow, netFlowChange: flow.subtracting(baseline.netFlow))
    }
}
