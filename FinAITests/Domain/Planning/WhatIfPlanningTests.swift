//
//  WhatIfPlanningTests.swift
//  FinAI
//
//  Created by Tommy on 23.10.26.
//

import Foundation
import Testing
@testable import FinAI

struct WhatIfPlanningTests {
    @Test(arguments: [
        (WhatIfScenario.Change.additionalExpense, 550, 1000, 540, 460, -200),
        (.additionalIncome, 350, 1200, 340, 860, 200),
        (.reducedExpenses, 150, 1000, 140, 860, 200),
        (.reducedIncome, 350, 800, 340, 460, -200)
    ])
    func appliesOneChangeWithExactReconciledAmounts(change: WhatIfScenario.Change, expenses: Int,
        income: Int, spending: Int, flow: Int, difference: Int) throws {
        let forecast = try report(remainingExpenses: 250)
        let result = try simulate(change, amount: 200, forecast: forecast)
        #expect(result.expenses.amount == Decimal(expenses))
        #expect(result.income.amount == Decimal(income))
        #expect(result.netSpending.amount == Decimal(spending))
        #expect(result.netFlow.amount == Decimal(flow))
        #expect(result.netFlowChange.amount == Decimal(difference))
    }

    @Test func expenseReductionCannotEraseRecordedExpenses() throws {
        let forecast = try report()
        let result = try simulate(.reducedExpenses, amount: 150, forecast: forecast)
        #expect(result.expenses.amount == 100)
        #expect(result.netSpending.amount == 90)
        #expect(throws: WhatIfScenario.ScenarioError.exceedsRemainingExpenses) {
            try simulate(.reducedExpenses, amount: 151, forecast: forecast)
        }
    }

    @Test func incomeReductionCannotEraseRecordedIncome() throws {
        let forecast = try report()
        #expect(try simulate(.reducedIncome, amount: 500, forecast: forecast).income.amount == 500)
        #expect(throws: WhatIfScenario.ScenarioError.exceedsRemainingIncome) {
            try simulate(.reducedIncome, amount: 501, forecast: forecast)
        }
    }

    @Test func refundsStayRecordedAndMayProduceNegativeNetSpending() throws {
        let forecast = try report(refunds: 400)
        let result = try simulate(.additionalExpense, amount: 10, forecast: forecast)
        #expect(result.expenses.amount == 260)
        #expect(result.netSpending.amount == -140)
        #expect(result.netFlow.amount == 1140)
        #expect(result.income.amount == 1000)
    }

    @Test(arguments: [Decimal.zero, Decimal(-1)])
    func nonpositiveAmountsAreRejected(amount: Decimal) throws {
        let forecast = try report()
        #expect(throws: WhatIfScenario.ScenarioError.invalidAmount) {
            try simulate(.additionalExpense, amount: amount, forecast: forecast)
        }
    }

    @Test func missingOrOtherCurrencyForecastIsUnavailable() throws {
        let forecast = try report(available: false)
        #expect(throws: WhatIfScenario.ScenarioError.unavailableForecast) {
            try simulate(.additionalExpense, amount: 10, forecast: forecast)
        }
        let scenario = try WhatIfScenario(change: .additionalExpense, money: Money(amount: 10, currency: .usd))
        #expect(throws: WhatIfScenario.ScenarioError.unavailableForecast) {
            try WhatIfPlanningService().simulate(scenario, forecast: report())
        }
    }

    @Test func anAvailableSecondCurrencyUsesOnlyItsOwnForecast() throws {
        let eur = try report()
        func usd(_ amount: Decimal) throws -> Money { try Money(amount: amount, currency: .usd) }
        let actual = try CurrencySummary(currency: .usd, income: usd(50), expenses: usd(10), refunds: usd(5),
                                         netSpending: usd(5), netFlow: usd(45))
        let projection = try MonthForecast.Projection(remainingVariableExpenses: usd(30),
            remainingRecurringExpenses: usd(0), remainingIncome: usd(50), expenses: usd(40),
            income: usd(100), netSpending: usd(35), netFlow: usd(65))
        let combined = MonthForecast(month: eur.month, basisMonth: eur.basisMonth, throughDay: eur.throughDay,
            remainingDays: eur.remainingDays, currencies: eur.currencies + [.init(recorded: actual, projection: projection)])
        let scenario = try WhatIfScenario(change: .additionalExpense, money: usd(5))
        let result = try WhatIfPlanningService().simulate(scenario, forecast: combined)
        #expect(try result.expenses == usd(45))
        #expect(try result.netSpending == usd(40))
        #expect(try result.netFlow == usd(60))
        #expect(try result.netFlowChange == usd(-5))
    }

    @Test func overflowIsRejectedRatherThanRoundingOrPublishingPartialResults() throws {
        let forecast = try report()
        #expect(throws: ValidationError.arithmeticFailure) {
            try simulate(.additionalExpense, amount: .greatestFiniteMagnitude, forecast: forecast)
        }
    }

    @Test func zeroRemainingEstimateAllowsAdditionalExpenseButNotReduction() throws {
        let forecast = try report(remainingExpenses: 0, remainingIncome: 0)
        #expect(try simulate(.additionalExpense, amount: 10, forecast: forecast).expenses.amount == 110)
        #expect(throws: WhatIfScenario.ScenarioError.exceedsRemainingExpenses) {
            try simulate(.reducedExpenses, amount: 1, forecast: forecast)
        }
        #expect(throws: WhatIfScenario.ScenarioError.exceedsRemainingIncome) {
            try simulate(.reducedIncome, amount: 1, forecast: forecast)
        }
    }

    private func simulate(_ change: WhatIfScenario.Change, amount: Decimal, forecast: MonthForecast) throws -> WhatIfResult {
        try WhatIfPlanningService().simulate(
            WhatIfScenario(change: change, money: Money(amount: amount, currency: .eur)), forecast: forecast)
    }

    private func report(remainingExpenses: Decimal = 150, remainingIncome: Decimal = 500,
                        refunds: Decimal = 10, available: Bool = true) throws -> MonthForecast {
        func money(_ amount: Decimal) throws -> Money { try Money(amount: amount, currency: .eur) }
        let actual = try CurrencySummary(currency: .eur, income: money(500), expenses: money(100),
            refunds: money(refunds), netSpending: money(100 - refunds), netFlow: money(400 + refunds))
        let spending = 100 + remainingExpenses - refunds
        let income = 500 + remainingIncome
        let projection = try MonthForecast.Projection(remainingVariableExpenses: money(remainingExpenses),
            remainingRecurringExpenses: money(0), remainingIncome: money(remainingIncome),
            expenses: money(100 + remainingExpenses), income: money(income), netSpending: money(spending), netFlow: money(income - spending))
        return MonthForecast(month: .distantPast, basisMonth: .distantPast, throughDay: .distantPast,
            remainingDays: remainingExpenses == 0 ? 0 : 5,
            currencies: [MonthForecast.CurrencyForecast(recorded: actual, projection: available ? projection : nil)])
    }
}
