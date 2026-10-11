//
//  BudgetPlanningTests.swift
//  FinAITests
//
//  Created by Tommy on 09.10.26.
//

import Foundation
import Testing
@testable import FinAI

struct BudgetPlanningTests {
    @Test func countsOnlyCategoryCurrencyAndCurrentMonthAcrossAccounts() throws {
        let month = try #require(TestFixtures.calendar.dateInterval(of: .month, for: TestFixtures.date))
        let rows = try [
            row(80), row(40), row(15, kind: .refund), row(999, kind: .transfer),
            row(999, kind: .income), row(999, kind: .adjustment), row(999, kind: .unknown),
            row(999, currency: Currency(code: "USD")), row(999, category: .shopping),
            row(999, date: month.start.addingTimeInterval(-1)), row(999, date: month.end),
            row(5, date: month.start)
        ]
        let budget = try CategoryBudget(id: UUID(), category: .groceries, limit: Money(amount: 100, currency: .eur))
        let result = try BudgetPlanningService().progress(for: budget, transactions: rows, on: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(result.spent.amount == 110)
        #expect(result.remaining.amount == -10)
        #expect(result.exceeded.amount == 10)
        #expect(result.month == month.start)
        #expect(result.spent.currency == .eur)
    }

    @Test func emptyAndRefundOnlyMonthsPreserveExactAmounts() throws {
        let budget = try CategoryBudget(id: UUID(), category: .groceries, limit: Money(amount: Decimal(string: "100.01") ?? 0, currency: .eur))
        let empty = try BudgetPlanningService().progress(for: budget, transactions: [], on: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(empty.spent.amount == 0)
        #expect(empty.remaining == budget.limit)
        let result = try BudgetPlanningService().progress(for: budget, transactions: [row(Decimal(string: "0.02") ?? 0, kind: .refund)], on: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(result.spent.amount == Decimal(string: "-0.02"))
        #expect(result.remaining.amount == Decimal(string: "100.03"))
        #expect(result.exceeded.amount == 0)
    }

    @Test func localizedDraftRoundTripsAndRejectsInvalidInput() throws {
        var draft = BudgetDraft()
        draft.limit = "123,45"
        draft.currencyCode = " usd "
        let locale = Locale(identifier: "de_DE")
        let budget = try draft.budget(id: UUID(), locale: locale)
        #expect(budget.limit.amount == Decimal(string: "123.45"))
        #expect(budget.limit.currency.code == "USD")
        #expect(try BudgetDraft(budget: budget, locale: locale).budget(id: budget.id, locale: locale) == budget)
        draft.limit = "0"
        #expect(throws: CategoryBudget.BudgetError.invalidAmount) { try draft.budget(id: UUID(), locale: locale) }
        draft.limit = "-1"
        #expect(throws: CategoryBudget.BudgetError.invalidAmount) { try draft.budget(id: UUID(), locale: locale) }
        draft.limit = "abc"
        #expect(throws: (any Error).self) { try draft.budget(id: UUID(), locale: locale) }
        draft.limit = "100"
        draft.category = .income
        #expect(throws: CategoryBudget.BudgetError.invalidCategory) { try draft.budget(id: UUID(), locale: locale) }
        draft.category = .transfers
        #expect(throws: CategoryBudget.BudgetError.invalidCategory) { try draft.budget(id: UUID(), locale: locale) }
    }

    @Test func excludesNonSpendingBeforeArithmeticAndRepeatsNextMonth() throws {
        let large = Decimal.greatestFiniteMagnitude
        let rows = try [row(large, kind: .income), row(large, kind: .income), row(20)]
        let budget = try CategoryBudget(id: UUID(), category: .groceries, limit: Money(amount: 100, currency: .eur))
        let current = try BudgetPlanningService().progress(for: budget, transactions: rows, on: TestFixtures.date, calendar: TestFixtures.calendar)
        #expect(current.spent.amount == 20)
        let nextMonth = try #require(TestFixtures.calendar.date(byAdding: .month, value: 1, to: TestFixtures.date))
        let next = try BudgetPlanningService().progress(for: budget, transactions: rows, on: nextMonth, calendar: TestFixtures.calendar)
        #expect(next.spent.amount == 0)
        #expect(next.remaining == budget.limit)
    }

    private func row(_ amount: Decimal, currency: Currency = .eur, category: FinAI.Category = .groceries,
                     kind: Transaction.Kind = .expense, date: Date = TestFixtures.date) throws -> Transaction {
        try Transaction(id: UUID(), accountID: UUID(), date: date, merchant: "Synthetic", rawDescription: "Synthetic",
                        money: Money(amount: amount, currency: currency), direction: kind == .income || kind == .refund ? .credit : .debit,
                        kind: kind, category: category, source: .demo)
    }
}
