//
//  RecurringPaymentTests.swift
//  FinAI
//
//  Created by Tommy on 30.09.26.
//

import Foundation
import Testing
@testable import FinAI

struct RecurringPaymentTests {
    private let calendar = TestFixtures.calendar
    private let account = UUID()

    @Test(arguments: [RecurringPayment.Cadence.weekly, .monthly, .yearly])
    func recognizesCadencesAndUsesSubscriptionCategory(_ cadence: RecurringPayment.Cadence) throws {
        let component: Calendar.Component = cadence == .weekly ? .day : cadence == .monthly ? .month : .year
        let anchor = try date(2024, 1, 15)
        let dates = try (0..<3).map { index in
            try #require(calendar.date(byAdding: component, value: cadence == .weekly ? index * 7 : index, to: anchor))
        }
        let rows = try dates.map { try row($0, category: .subscriptions) }
        let report = detect(rows, asOf: dates[2])
        let payment = try #require(report.first)
        #expect(report.count == 1)
        #expect(payment.cadence == cadence)
        #expect(payment.money.amount == Decimal(string: "12.99"))
        #expect(payment.transactionIDs == rows.map(\.id))
        #expect(payment.isSubscriptionCandidate)
        #expect(payment.isStale == false)
        #expect(detect(rows.reversed(), asOf: dates[2]) == report)
    }

    @Test func monthEndsUseOriginalAnchorWithoutFebruaryDrift() throws {
        let rows = try [date(2026, 1, 31), date(2026, 2, 28), date(2026, 3, 31)].map { try row($0) }
        let payment = try #require(detect(rows).first)
        #expect(payment.expectedDate == (try date(2026, 4, 30)))
        #expect(payment.isSubscriptionCandidate == false)
    }

    @Test func acceptsSmallPostingDelaysButRejectsDriftingDatesAndMissingMonths() throws {
        let delayed = try [date(2026, 1, 15), date(2026, 2, 17), date(2026, 3, 14)].map { try row($0) }
        #expect(detect(delayed).count == 1)
        let irregular = try [date(2026, 1, 15), date(2026, 2, 19), date(2026, 3, 23)].map { try row($0) }
        #expect(detect(irregular).isEmpty)
        let missing = try [date(2026, 1, 15), date(2026, 3, 15), date(2026, 4, 15)].map { try row($0) }
        #expect(detect(missing).isEmpty)
    }

    @Test func rejectsInsufficientHistoryDuplicatesAndIrregularExtraPayments() throws {
        let rows = try monthlyRows()
        #expect(detect(Array(rows.prefix(2))).isEmpty)
        #expect(detect(rows + [rows[1]]).isEmpty)
        #expect(detect(rows + [try row(date(2026, 2, 20))]).isEmpty)
        #expect(detect([]).isEmpty)
    }

    @Test func neverCombinesAccountsCurrenciesMerchantsOrAmounts() throws {
        let dates = try [date(2026, 1, 15), date(2026, 2, 15), date(2026, 3, 15)]
        let rows = try [row(dates[0]), row(dates[1]), row(dates[2], accountID: UUID())]
        #expect(detect(rows).isEmpty)
        #expect(detect(try [row(dates[0]), row(dates[1]), row(dates[2], currency: .usd)]).isEmpty)
        #expect(detect(try [row(dates[0]), row(dates[1]), row(dates[2], merchant: "Other")]).isEmpty)
        #expect(detect(try [row(dates[0]), row(dates[1]), row(dates[2], amount: 13)]).isEmpty)
        let eur = try monthlyRows()
        let usd = try dates.map { try row($0, currency: .usd) }
        #expect(detect(eur + usd).count == 2)
        #expect(detect(eur + usd).map(\.money.currency) == [.eur, .usd])
    }

    @Test(arguments: [Transaction.Kind.income, .transfer, .refund, .adjustment, .unknown])
    func excludesNonexpenses(_ kind: Transaction.Kind) throws {
        #expect(detect(try monthlyRows(kind: kind)).isEmpty)
    }

    @Test func excludesZeroEmptyMerchantsAndFutureTransactions() throws {
        let dates = try [date(2026, 1, 15), date(2026, 2, 15), date(2026, 3, 15)]
        #expect(detect(try dates.map { try row($0, amount: 0) }).isEmpty)
        #expect(detect(try dates.map { try row($0, merchant: "  ") }).isEmpty)
        #expect(detect(try monthlyRows(), asOf: try date(2026, 3, 14)).isEmpty)
    }

    @Test func stalePatternsRetainMissingExpectedDateAndRespectGraceWindow() throws {
        let rows = try monthlyRows()
        let current = try #require(detect(rows, asOf: date(2026, 4, 18)).first)
        #expect(current.isStale == false)
        let stale = try #require(detect(rows, asOf: date(2026, 6, 1)).first)
        #expect(stale.isStale)
        #expect(stale.expectedDate == (try date(2026, 4, 15)))
    }

    @Test func weeklyMatchingUsesCalendarDaysAcrossDaylightSaving() throws {
        var berlin = calendar
        berlin.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        let dates = try [22, 29].map {
            try #require(berlin.date(from: DateComponents(year: 2026, month: 3, day: $0, hour: 12)))
        } + [try #require(berlin.date(from: DateComponents(year: 2026, month: 4, day: 5, hour: 12)))]
        let rows = try dates.map { try row($0) }
        let payment = try #require(RecurringPaymentService().detect(rows, date: dates[2], calendar: berlin).first)
        #expect(payment.cadence == .weekly)
        #expect(berlin.component(.day, from: payment.expectedDate) == 12)
    }

    @Test func overviewIncludesDemoRentAndSubscriptionWithoutMutatingSnapshot() throws {
        let snapshot = try DemoData().make(referenceDate: TestFixtures.date, calendar: calendar)
        let overview = try FinanceOverview.make(snapshot: snapshot, date: TestFixtures.date, calendar: calendar)
        #expect(overview.snapshot == snapshot)
        #expect(overview.recurringPayments.contains { $0.merchant == "Demo rent" && !$0.isSubscriptionCandidate })
        #expect(overview.recurringPayments.contains { $0.merchant == "Spotify" && $0.isSubscriptionCandidate })
    }

    private func monthlyRows(kind: Transaction.Kind = .expense) throws -> [Transaction] {
        try [date(2026, 1, 15), date(2026, 2, 15), date(2026, 3, 15)].map { try row($0, kind: kind) }
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private func detect(_ rows: [Transaction], asOf: Date = TestFixtures.date) -> [RecurringPayment] {
        RecurringPaymentService().detect(rows, date: asOf, calendar: calendar)
    }

    private func row(
        _ date: Date, accountID: UUID? = nil, currency: Currency = .eur,
        merchant: String = "Test service", amount: Decimal = Decimal(string: "12.99") ?? 0,
        kind: Transaction.Kind = .expense, category: FinAI.Category = .other
    ) throws -> Transaction {
        try Transaction(
            id: UUID(), accountID: accountID ?? account, date: date, merchant: merchant,
            rawDescription: "Original", money: Money(amount: amount, currency: currency),
            direction: kind == .income || kind == .refund ? .credit : .debit,
            kind: kind, category: category, source: .demo
        )
    }
}
