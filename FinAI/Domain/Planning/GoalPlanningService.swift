//
//  GoalPlanningService.swift
//  FinAI
//
//  Created by Tommy on 08.10.26.
//

import Foundation

struct GoalPlanningService {
    /// Includes the current calendar month and deadline month as contribution opportunities.
    /// The result describes a schedule, not whether the user can afford it.
    func plan(for goal: SavingsGoal, on date: Date, calendar: Calendar) throws -> GoalPlan {
        try goal.validate()
        guard date.timeIntervalSinceReferenceDate.isFinite else { throw SavingsGoal.GoalError.invalidDate }
        let currency = goal.target.currency
        if goal.saved.amount >= goal.target.amount {
            return GoalPlan(remaining: .zero(currency), contributionMonths: 0,
                            monthlyContribution: .zero(currency), status: .completed)
        }
        let remaining = try goal.target.subtracting(goal.saved)
        guard calendar.startOfDay(for: date) <= calendar.startOfDay(for: goal.deadline) else {
            return GoalPlan(remaining: remaining, contributionMonths: 0, monthlyContribution: nil, status: .overdue)
        }
        guard let start = calendar.dateInterval(of: .month, for: date)?.start,
              let end = calendar.dateInterval(of: .month, for: goal.deadline)?.start,
              let difference = calendar.dateComponents([.month], from: start, to: end).month,
              difference >= 0, difference < Int.max else { throw SavingsGoal.GoalError.invalidDate }
        let months = difference + 1
        var amount = remaining.amount
        var divisor = Decimal(months)
        var quotient = Decimal.zero
        let error = NSDecimalDivide(&quotient, &amount, &divisor, .up)
        guard error == .noError || error == .lossOfPrecision else { throw ValidationError.arithmeticFailure }
        // Foundation supplies the currency's display precision (for example EUR 2, JPY 0, KWD 3).
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        var rounded = Decimal.zero
        NSDecimalRound(&rounded, &quotient, formatter.maximumFractionDigits, .up)
        return GoalPlan(remaining: remaining, contributionMonths: months,
                        monthlyContribution: try Money(amount: rounded, currency: currency), status: .active)
    }
}
