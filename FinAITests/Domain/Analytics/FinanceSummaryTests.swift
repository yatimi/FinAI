//
//  FinanceSummaryTests.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import Testing
@testable import FinAI

struct FinanceSummaryTests {
    @Test func separatesCurrenciesAndExcludesTransfersAndAdjustments() throws {
        let transactions = try [
            TestFixtures.transaction(amount: 1000, kind: .income),
            TestFixtures.transaction(amount: 100),
            TestFixtures.transaction(amount: 20, kind: .refund),
            TestFixtures.transaction(amount: 400, kind: .transfer),
            TestFixtures.transaction(amount: 900, kind: .adjustment),
            TestFixtures.transaction(amount: 600, kind: .unknown),
            TestFixtures.transaction(amount: 50, currency: .usd)
        ]
        let result = try FinanceSummaryService().summarize(
            transactions, from: TestFixtures.date, to: TestFixtures.date.addingTimeInterval(1)
        )
        let euros = try #require(result.first { $0.currency == .eur })
        let dollars = try #require(result.first { $0.currency == .usd })
        #expect(result.count == 2)
        #expect(euros.income.amount == 1000)
        #expect(euros.expenses.amount == 100)
        #expect(euros.refunds.amount == 20)
        #expect(euros.netSpending.amount == 80)
        #expect(euros.netFlow.amount == 920)
        #expect(dollars.netFlow.amount == -50)
    }

    @Test func usesHalfOpenDateInterval() throws {
        let start = TestFixtures.date
        let end = start.addingTimeInterval(86400)
        let transactions = try [
            TestFixtures.transaction(amount: 10, date: start.addingTimeInterval(-1)),
            TestFixtures.transaction(amount: 20, date: start),
            TestFixtures.transaction(amount: 30, date: end.addingTimeInterval(-1)),
            TestFixtures.transaction(amount: 40, date: end)
        ]
        let summary = try #require(FinanceSummaryService().summarize(transactions, from: start, to: end).first)
        #expect(summary.expenses.amount == 50)
        #expect(try FinanceSummaryService().summarize([], from: start, to: end).isEmpty)
    }

    @Test func refundOnlyPeriodDoesNotBecomeIncome() throws {
        let refund = try TestFixtures.transaction(amount: 120, kind: .refund)
        let result = try #require(FinanceSummaryService().summarize(
            [refund], from: TestFixtures.date, to: TestFixtures.date.addingTimeInterval(1)
        ).first)
        #expect(result.income.amount == 0)
        #expect(result.netSpending.amount == -120)
        #expect(result.netFlow.amount == 120)
    }

    @Test func monthUsesInjectedCalendarAndTimeZone() throws {
        var calendar = TestFixtures.calendar
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 31, hour: 23)))
        let overview = try FinanceOverview.make(snapshot: .empty, date: date, calendar: calendar)
        #expect(calendar.component(.day, from: overview.month) == 1)
        #expect(calendar.component(.month, from: overview.month) == 3)
    }
}
