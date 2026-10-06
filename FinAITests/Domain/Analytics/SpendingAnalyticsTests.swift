//
//  SpendingAnalyticsTests.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import Foundation
import Testing
@testable import FinAI

struct SpendingAnalyticsTests {
    private let calendar = TestFixtures.calendar

    @Test func groupsCategoriesAndSavedMerchantsAndKeepsCurrenciesSeparate() throws {
        let rows = try [
            transaction(100, merchant: "REWE", category: .groceries),
            transaction(25, merchant: "REWE", category: .groceries),
            transaction(10, kind: .refund, merchant: "REWE", category: .groceries),
            transaction(40, merchant: "Cafe", category: .restaurants),
            transaction(200, currency: .usd, merchant: "REWE", category: .groceries),
            transaction(1000, kind: .income), transaction(500, kind: .transfer),
            transaction(300, kind: .adjustment), transaction(900, kind: .unknown)
        ]
        let report = try analyze(rows)
        #expect(report.currencies.map(\.currency) == [.eur, .usd])
        let eur = try #require(report.currencies.first)
        #expect(eur.current.amount == 155)
        #expect(eur.categories.map(\.group) == [.category(.groceries), .category(.restaurants)])
        let rewe = try #require(eur.merchants.first)
        #expect(rewe.group == .merchant("REWE"))
        #expect(rewe.expenses.amount == 125)
        #expect(rewe.refunds.amount == 10)
        #expect(rewe.netSpending.amount == 115)
        #expect(report.currencies.last?.current.amount == 200)
        #expect(eur.categories.reduce(Decimal.zero) { $0 + $1.netSpending.amount } == eur.current.amount)
        #expect(eur.merchants.reduce(Decimal.zero) { $0 + $1.netSpending.amount } == eur.current.amount)
    }

    @Test func comparesUnionOfCurrenciesWithCheckedDecimalArithmetic() throws {
        let previous = try previousDate()
        let rows = try [
            transaction(120), transaction(20, kind: .refund), transaction(80, date: previous),
            transaction(40, currency: .usd, date: previous),
            transaction(5, currency: Currency(code: "GBP"))
        ]
        let report = try analyze(rows)
        let eur = try #require(report.currencies.first { $0.currency == .eur })
        #expect(eur.current.amount == 100)
        #expect(eur.previous.amount == 80)
        #expect(eur.change.amount == 20)
        #expect(eur.changeRatio == Decimal(string: "0.25"))
        let usd = try #require(report.currencies.first { $0.currency == .usd })
        #expect(usd.current.amount == 0)
        #expect(usd.change.amount == -40)
        #expect(usd.changeRatio == -1)
        #expect(usd.categories.isEmpty)
        let gbp = try #require(report.currencies.first { $0.currency.code == "GBP" })
        #expect(gbp.previous.amount == 0)
        #expect(gbp.changeRatio == nil)
    }

    @Test(arguments: [Decimal.zero, Decimal(-20)])
    func noPercentageForNonpositiveBaseline(_ baseline: Decimal) throws {
        let rows = try [transaction(10), transaction(-baseline, kind: .refund, date: previousDate())]
        let summary = try #require(analyze(rows).currencies.first)
        #expect(summary.previous.amount == baseline)
        #expect(summary.change.amount == 10 - baseline)
        #expect(summary.changeRatio == nil)
    }

    @Test func refundOnlyMonthIsNegativeSpendingAndUsesRecordedCategory() throws {
        let row = try transaction(12, kind: .refund, merchant: "Shop", category: .shopping)
        let summary = try #require(analyze([row]).currencies.first)
        #expect(summary.current.amount == -12)
        #expect(summary.categories.first?.group == .category(.shopping))
        #expect(summary.categories.first?.expenses.amount == 0)
        #expect(summary.merchants.first?.netSpending.amount == -12)
    }

    @Test(arguments: [1, 3])
    func calendarBoundariesAcrossYearAndDaylightSaving(_ month: Int) throws {
        var berlin = calendar
        berlin.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        let date = try #require(berlin.date(from: DateComponents(year: 2026, month: month, day: 31, hour: 12)))
        let current = try #require(berlin.dateInterval(of: .month, for: date))
        let previousDate = try #require(berlin.date(byAdding: .month, value: -1, to: current.start))
        let previous = try #require(berlin.dateInterval(of: .month, for: previousDate))
        let rows = try [
            transaction(999, date: previous.start.addingTimeInterval(-1)),
            transaction(10, date: previous.start),
            transaction(20, date: current.start.addingTimeInterval(-1)),
            transaction(40, date: current.start),
            transaction(50, date: current.end.addingTimeInterval(-1)),
            transaction(999, date: current.end)
        ]
        let report = try SpendingAnalyticsService().analyze(rows, date: date, calendar: berlin)
        #expect(report.month == current.start)
        #expect(report.previousMonth == previous.start)
        #expect(report.currencies.first?.current.amount == 90)
        #expect(report.currencies.first?.previous.amount == 30)
    }

    @Test func emptyAndNonSpendingDataProduceNoRows() throws {
        #expect(try analyze([]).currencies.isEmpty)
        #expect(try analyze([transaction(30, kind: .income), transaction(50, kind: .transfer)]).currencies.isEmpty)
    }

    @Test func tiedRowsHaveStableOrderRegardlessOfInputOrder() throws {
        let rows = try [transaction(10, merchant: "B"), transaction(10, merchant: "A")]
        let report = try analyze(rows)
        #expect(try analyze(rows.reversed()) == report)
        #expect(report.currencies.first?.merchants.map(\.group) == [.merchant("A"), .merchant("B")])
    }

    @Test func rejectsOverflowInsteadOfReturningPartialTotals() throws {
        let maximum = Decimal.greatestFiniteMagnitude
        let rows = try [transaction(maximum), transaction(maximum)]
        #expect(throws: ValidationError.arithmeticFailure) { try analyze(rows) }
    }

    @Test func repeatingPercentageDoesNotLoseMonetaryPrecision() throws {
        let rows = try [transaction(4), transaction(3, date: previousDate())]
        let result = try #require(analyze(rows).currencies.first)
        #expect(result.change.amount == 1)
        let ratio = try #require(result.changeRatio)
        #expect(ratio > (Decimal(string: "0.333333") ?? 0))
        #expect(ratio < (Decimal(string: "0.333334") ?? 1))
    }

    @Test func overviewIntegratesAnalyticsForTheSameSnapshotAndMonth() throws {
        let snapshot = try DemoData().make(referenceDate: TestFixtures.date, calendar: calendar)
        let overview = try FinanceOverview.make(snapshot: snapshot, date: TestFixtures.date, calendar: calendar)
        #expect(overview.spending.month == overview.month)
        for row in overview.spending.currencies {
            let summary = overview.summaries.first { $0.currency == row.currency }
            #expect(row.current == (summary?.netSpending ?? .zero(row.currency)))
        }
    }

    private func analyze(_ rows: [Transaction]) throws -> SpendingAnalytics {
        try SpendingAnalyticsService().analyze(rows, date: TestFixtures.date, calendar: calendar)
    }

    private func previousDate() throws -> Date {
        try #require(calendar.date(byAdding: .month, value: -1, to: TestFixtures.date))
    }

    private func transaction(
        _ amount: Decimal, currency: Currency = .eur, kind: Transaction.Kind = .expense,
        date: Date = TestFixtures.date, merchant: String = "Shop", category: FinAI.Category = .other
    ) throws -> Transaction {
        try Transaction(
            id: UUID(), accountID: UUID(), date: date, merchant: merchant, rawDescription: "Original",
            money: Money(amount: amount, currency: currency),
            direction: kind == .income || kind == .refund ? .credit : .debit,
            kind: kind, category: category, source: .demo
        )
    }
}
