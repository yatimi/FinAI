//
//  GoalPlanningTests.swift
//  FinAITests
//
//  Created by Tommy on 08.10.26.
//

import Foundation
import Testing
@testable import FinAI

struct GoalPlanningTests {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = .gmt
        return value
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private func goal(target: Decimal = 2500, saved: Decimal = 500, currency: Currency = .eur,
                      deadline: Date) throws -> SavingsGoal {
        SavingsGoal(id: UUID(), name: "MacBook", target: try Money(amount: target, currency: currency),
                    saved: try Money(amount: saved, currency: currency), deadline: deadline)
    }

    @Test func includesCurrentAndDeadlineMonthAndRoundsUp() throws {
        let goal = try goal(deadline: date(2026, 12, 31))
        let plan = try GoalPlanningService().plan(for: goal, on: date(2026, 10, 8), calendar: calendar)
        #expect(plan.remaining.amount == 2000)
        #expect(plan.contributionMonths == 3)
        #expect(plan.monthlyContribution?.amount == Decimal(string: "666.67"))
        #expect(plan.status == .active)
    }

    @Test func deadlineTodayAllowsOneContributionAndYesterdayIsOverdue() throws {
        let today = try date(2026, 10, 8)
        let service = GoalPlanningService()
        let dueToday = try service.plan(for: goal(deadline: today), on: today, calendar: calendar)
        #expect(dueToday.contributionMonths == 1)
        #expect(dueToday.monthlyContribution?.amount == 2000)
        let overdue = try service.plan(for: goal(deadline: date(2026, 10, 7)), on: today, calendar: calendar)
        #expect(overdue.status == .overdue)
        #expect(overdue.monthlyContribution == nil)
        #expect(overdue.remaining.amount == 2000)
    }

    @Test func completedGoalsHaveNoRemainingContributionEvenAfterDeadline() throws {
        let plan = try GoalPlanningService().plan(
            for: goal(saved: 3000, deadline: date(2026, 1, 1)), on: date(2026, 10, 8), calendar: calendar)
        #expect(plan.status == .completed)
        #expect(plan.remaining == .zero(.eur))
        #expect(plan.monthlyContribution == .zero(.eur))
    }

    @Test func crossesYearAndLeapDayUsingCalendarMonths() throws {
        let plan = try GoalPlanningService().plan(
            for: goal(deadline: date(2028, 2, 29)), on: date(2027, 12, 31), calendar: calendar)
        #expect(plan.contributionMonths == 3)
    }

    @Test func rejectsMixedCurrenciesAndInvalidAmounts() throws {
        let deadline = try date(2026, 12, 31)
        let mixed = SavingsGoal(id: UUID(), name: "Goal", target: try Money(amount: 10, currency: .eur),
                               saved: try Money(amount: 1, currency: .usd), deadline: deadline)
        #expect(throws: ValidationError.currencyMismatch) { try mixed.validate() }
        #expect(throws: SavingsGoal.GoalError.invalidAmount) { try goal(target: 0, deadline: deadline).validate() }
        #expect(throws: SavingsGoal.GoalError.invalidAmount) { try goal(saved: -1, deadline: deadline).validate() }
    }

    @Test(arguments: [("JPY", "667"), ("KWD", "666.667"), ("EUR", "666.67")])
    func respectsCurrencyPrecision(code: String, expected: String) throws {
        let currency = try Currency(code: code)
        let plan = try GoalPlanningService().plan(
            for: goal(currency: currency, deadline: date(2026, 12, 31)), on: date(2026, 10, 8), calendar: calendar)
        #expect(plan.monthlyContribution?.amount == Decimal(string: expected))
        #expect(plan.monthlyContribution?.currency == currency)
    }

    @Test func draftUsesExactLocalizedAmountsAndRejectsMalformedInput() throws {
        let original = try goal(target: Decimal(string: "2500.25") ?? 0, deadline: date(2026, 12, 31))
        let locale = Locale(identifier: "de_DE")
        var draft = GoalDraft(goal: original, locale: locale)
        #expect(draft.target == "2500,25")
        #expect(try draft.goal(id: original.id, locale: locale) == original)
        draft.target = "12,3,4"
        #expect(throws: ImportError.invalidAmount) { try draft.goal(id: original.id, locale: locale) }
        draft.target = "100"
        draft.name = "  \n "
        #expect(throws: SavingsGoal.GoalError.invalidName) { try draft.goal(id: original.id, locale: locale) }
    }
}
