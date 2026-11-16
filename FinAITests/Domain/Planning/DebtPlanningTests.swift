//
//  DebtPlanningTests.swift
//  FinAITests
//
//  Created by Tommy on 25.10.26.
//

import Foundation
import Testing
@testable import FinAI

struct DebtPlanningTests {
    private let service = DebtPlanningService()
    private let date = TestFixtures.date
    private let calendar = TestFixtures.calendar

    func debt(direction: PersonalDebt.Direction = .iOwe, amount: Decimal = 100, currency: Currency = .eur,
              due: Date? = nil, repayments: [DebtRepayment] = []) throws -> PersonalDebt {
        try PersonalDebt(id: UUID(), person: "Alex", direction: direction, principal: Money(amount: amount, currency: currency),
                         date: date, dueDate: due, repayments: repayments)
    }

    @Test(arguments: PersonalDebt.Direction.allCases)
    func partialAndFullRepayment(direction: PersonalDebt.Direction) throws {
        let original = try debt(direction: direction)
        let payment = try DebtRepayment(id: UUID(), amount: Money(amount: try #require(Decimal(string: "30.15")), currency: .eur), date: date)
        let updated = try service.adding(payment, to: original, on: date, calendar: calendar)
        let progress = try service.progress(for: updated, on: date, calendar: calendar)
        #expect(progress.remaining.amount == Decimal(string: "69.85"))
        #expect(progress.repaid == payment.amount)
        #expect(progress.status == .active)
        #expect(original.repayments.isEmpty)
        let final = DebtRepayment(id: UUID(), amount: progress.remaining, date: date)
        let settled = try service.adding(final, to: updated, on: date, calendar: calendar)
        #expect(try service.progress(for: settled, on: date, calendar: calendar).status == .settled)
        #expect(settled.principal == original.principal)
    }

    @Test func rejectsOverpaymentWrongCurrencyAndDuplicateIDs() throws {
        let original = try debt()
        let over = try DebtRepayment(id: UUID(), amount: Money(amount: 101, currency: .eur), date: date)
        #expect(throws: PersonalDebt.DebtError.overpayment) { try service.adding(over, to: original, on: date, calendar: calendar) }
        let foreign = try DebtRepayment(id: UUID(), amount: Money(amount: 10, currency: Currency(code: "USD")), date: date)
        #expect(throws: ValidationError.currencyMismatch) { try service.adding(foreign, to: original, on: date, calendar: calendar) }
        let payment = try DebtRepayment(id: UUID(), amount: Money(amount: 10, currency: .eur), date: date)
        let partial = try service.adding(payment, to: original, on: date, calendar: calendar)
        #expect(throws: PersonalDebt.DebtError.invalid) { try service.adding(payment, to: partial, on: date, calendar: calendar) }
    }

    @Test(arguments: [Decimal(-1), Decimal(0)])
    func rejectsNonpositivePrincipalAndRepayment(amount: Decimal) throws {
        #expect(throws: PersonalDebt.DebtError.invalid) { try service.progress(for: debt(amount: amount), on: date, calendar: calendar) }
        let repayment = try DebtRepayment(id: UUID(), amount: Money(amount: amount, currency: .eur), date: date)
        #expect(throws: PersonalDebt.DebtError.invalid) { try service.adding(repayment, to: debt(), on: date, calendar: calendar) }
    }

    @Test func datesAndDueTodayUseCalendarDays() throws {
        let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: date))
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: date))
        let original = try debt(due: date)
        #expect(try service.progress(for: original, on: date, calendar: calendar).status == .active)
        #expect(try service.progress(for: original, on: tomorrow, calendar: calendar).status == .overdue)
        for invalid in [yesterday, tomorrow] {
            let repayment = try DebtRepayment(id: UUID(), amount: Money(amount: 10, currency: .eur), date: invalid)
            #expect(throws: PersonalDebt.DebtError.invalid) { try service.adding(repayment, to: original, on: date, calendar: calendar) }
        }
        #expect(throws: PersonalDebt.DebtError.invalid) { try service.progress(for: debt(due: yesterday), on: date, calendar: calendar) }
        #expect(throws: PersonalDebt.DebtError.invalid) { try service.progress(for: original, on: yesterday, calendar: calendar) }
    }

    @Test func draftsParseRegionalAmountsAndExplicitCurrency() throws {
        var draft = DebtDraft(date: date)
        draft.person = "  Alex  "
        draft.amount = "123,45"
        draft.currencyCode = "usd"
        draft.direction = .owedToMe
        let value = try draft.debt(id: UUID(), locale: Locale(identifier: "de_DE"))
        #expect(value.person == "Alex")
        #expect(value.principal.amount == Decimal(string: "123.45"))
        #expect(value.principal.currency.code == "USD")
        #expect(value.dueDate == nil)
        let payment = try RepaymentDraft(amount: "23,45", date: date).repayment(id: UUID(), currency: value.principal.currency, locale: Locale(identifier: "de_DE"))
        #expect(try service.progress(for: service.adding(payment, to: value, on: date, calendar: calendar), on: date, calendar: calendar).remaining.amount == 100)
        draft.amount = "invalid"
        #expect(throws: (any Error).self) { try draft.debt(id: UUID(), locale: Locale(identifier: "de_DE")) }
    }

    @Test func checkedArithmeticRejectsLossOfPrecision() throws {
        let principal = try Money(amount: try #require(Decimal(string: "1e127")), currency: .eur)
        let value = PersonalDebt(id: UUID(), person: "Alex", direction: .iOwe, principal: principal, date: date, dueDate: nil)
        let payment = try DebtRepayment(id: UUID(), amount: Money(amount: 1, currency: .eur), date: date)
        #expect(throws: ValidationError.arithmeticFailure) { try service.adding(payment, to: value, on: date, calendar: calendar) }
    }
}
