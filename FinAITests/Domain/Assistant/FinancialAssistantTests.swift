//
//  FinancialAssistantTests.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import Foundation
import Testing
@testable import FinAI

struct FinancialAssistantTests {
    private let service = FinancialAssistant()
    private let calendar = TestFixtures.calendar
    private let date = TestFixtures.date

    @Test func spendingUsesExactArithmeticRefundsAndOriginalCurrencies() throws {
        let amount = try #require(Decimal(string: "0.10"))
        let rows = try [TestFixtures.transaction(amount: amount), TestFixtures.transaction(amount: amount),
                        TestFixtures.transaction(amount: amount, kind: .refund),
                        TestFixtures.transaction(amount: 999, kind: .income),
                        TestFixtures.transaction(amount: 888, kind: .transfer),
                        TestFixtures.transaction(amount: 777, kind: .unknown),
                        TestFixtures.transaction(amount: 666, kind: .adjustment),
                        TestFixtures.transaction(amount: 25, currency: .usd)]
        let answer = try ask(.init(kind: .spending), rows)
        #expect(answer.report.currencies.first { $0.currency == .eur }?.current.amount == amount)
        #expect(answer.report.currencies.first { $0.currency == .usd }?.current.amount == 25)
        #expect(answer.categoryChanges.isEmpty)
    }

    @Test func comparisonIncludesDisappearingCategoriesAndRefundOnlyCurrency() throws {
        let previous = try #require(calendar.date(byAdding: .month, value: -1, to: date))
        let rows = try [row("Shop", amount: 40, category: .shopping),
                        row("Rent", amount: 100, category: .housing, date: previous),
                        row("Shop", amount: 10, category: .shopping, date: previous),
                        TestFixtures.transaction(amount: 3, currency: .usd, kind: .refund)]
        let answer = try ask(.init(kind: .comparison), rows)
        let eur = try #require(answer.report.currencies.first { $0.currency == .eur })
        #expect(eur.current.amount == 40)
        #expect(eur.previous.amount == 110)
        #expect(eur.change.amount == -70)
        #expect(answer.categoryChanges.first { $0.category == .housing }?.change.amount == -100)
        #expect(answer.categoryChanges.first { $0.category == .shopping }?.change.amount == 30)
        #expect(answer.report.currencies.first { $0.currency == .usd }?.current.amount == -3)
        for currency in answer.report.currencies {
            let reconciled = try answer.categoryChanges.filter { $0.change.currency == currency.currency }
                .reduce(Money.zero(currency.currency)) { try $0.adding($1.change) }
            #expect(reconciled == currency.change)
        }
    }

    @Test func lastMonthUsesCalendarBoundariesAndIgnoresOutsideArithmetic() throws {
        var berlin = calendar
        berlin.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        let now = try #require(berlin.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let month = try #require(berlin.dateInterval(of: .month, for: now))
        let previous = try #require(berlin.date(byAdding: .month, value: -1, to: month.start))
        let prior = try #require(berlin.date(byAdding: .month, value: -1, to: previous))
        let outside = try #require(berlin.date(byAdding: .month, value: -1, to: prior))
        let rows = try [TestFixtures.transaction(amount: 10, date: previous),
                        TestFixtures.transaction(amount: 20, date: month.start.addingTimeInterval(-1)),
                        TestFixtures.transaction(amount: 50, date: month.start),
                        TestFixtures.transaction(amount: 5, date: prior),
                        TestFixtures.transaction(amount: Decimal.greatestFiniteMagnitude, date: outside),
                        TestFixtures.transaction(amount: Decimal.greatestFiniteMagnitude, date: outside)]
        let answer = try service.answer(.init(kind: .comparison, period: .lastMonth),
                                        snapshot: .init(accounts: [], transactions: rows), date: now, calendar: berlin)
        #expect(answer.report.month == previous)
        #expect(answer.report.currencies.first?.current.amount == 30)
        #expect(answer.report.currencies.first?.previous.amount == 5)
        #expect(answer.categoryChanges.first?.change.amount == 25)
    }

    @Test func merchantResolvesSavedNameAndDrilldownMatchesOnlyItsRecords() throws {
        let expense = try row("REWE", amount: 20)
        let refund = try row("REWE", amount: 5, kind: .refund)
        let outlet = try row("REWE Outlet", amount: 100)
        let rows = [expense, refund, outlet]
        let answer = try ask(.init(kind: .merchant, merchant: " rewe "), rows)
        #expect(answer.query.merchant == "REWE")
        #expect(answer.report.currencies.first?.current.amount == 15)
        let drilldown = SpendingDrilldown(month: answer.report.month, currency: .eur, group: .merchant("REWE"))
        #expect(Set(drilldown.transactions(in: .init(accounts: [], transactions: rows), calendar: calendar).map(\.id)) == Set([expense.id, refund.id]))
        #expect(throws: AssistantError.merchantNotFound) { try ask(.init(kind: .merchant, merchant: "RE"), rows) }
        #expect(throws: AssistantError.ambiguousMerchant) {
            try ask(.init(kind: .merchant, merchant: "ReWe"), [expense, row("rewe", amount: 3)])
        }
    }

    @Test func chosenExactNameDisambiguatesCaseVariantsAndPreservesLongSavedNames() throws {
        let name = String(repeating: "A", count: 201)
        let rows = try [row("REWE", amount: 1), row("rewe", amount: 2), row(name, amount: 3)]
        #expect(try ask(.init(kind: .merchant, merchant: "rewe"), rows).report.currencies.first?.current.amount == 2)
        #expect(try ask(.init(kind: .merchant, merchant: name), rows).query.merchant == name)
    }

    @Test func unsupportedCombinationsAndEmptyNamesAreRejected() throws {
        #expect(throws: AssistantError.unsupportedQuestion) { try ask(.init(kind: .spending, merchant: "Shop"), []) }
        #expect(throws: AssistantError.unsupportedQuestion) { try ask(.init(kind: .merchant, merchant: " "), []) }
        #expect(throws: AssistantError.unsupportedQuestion) { try ask(.init(kind: .merchant), []) }
    }

    @Test func emptySnapshotAndArithmeticFailureAreExplicit() throws {
        let answer = try ask(.init(kind: .spending), [])
        #expect(answer.report.currencies.isEmpty)
        let huge = try TestFixtures.transaction(amount: Decimal.greatestFiniteMagnitude)
        #expect(throws: ValidationError.arithmeticFailure) { try ask(.init(kind: .spending), [huge, huge]) }
    }

    @Test func cancellationPreventsComputation() async throws {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try service.answer(.init(kind: .spending), snapshot: .empty, date: date, calendar: calendar)
        }
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    private func ask(_ query: AssistantQuery, _ rows: [Transaction]) throws -> AssistantAnswer {
        try service.answer(query, snapshot: .init(accounts: [], transactions: rows), date: date, calendar: calendar)
    }

    private func row(_ merchant: String, amount: Decimal, category: FinAI.Category = .other,
                     date: Date = TestFixtures.date, kind: Transaction.Kind = .expense) throws -> Transaction {
        try Transaction(id: UUID(), accountID: UUID(), date: date, merchant: merchant, rawDescription: "Source description",
                        money: Money(amount: amount, currency: .eur), direction: kind == .refund ? .credit : .debit,
                        kind: kind, category: category, source: .demo)
    }
}
