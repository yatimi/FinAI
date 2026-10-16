//
//  SpendingTimelineTests.swift
//  FinAI
//
//  Created by Tommy on 16.10.26.
//

import Foundation
import Testing
@testable import FinAI

struct SpendingTimelineTests {
    @Test func dailyTotalsReconcileWithReportAndKeepRefundsAndCurrenciesSeparate() throws {
        let calendar = TestFixtures.calendar
        let date = TestFixtures.date
        let nextDay = try #require(calendar.date(byAdding: .day, value: 1, to: date))
        let rows = try [
            TestFixtures.transaction(amount: 20, date: date),
            TestFixtures.transaction(amount: 5, kind: .refund, date: date),
            TestFixtures.transaction(amount: 3, kind: .refund, date: nextDay),
            TestFixtures.transaction(amount: 700, kind: .income),
            TestFixtures.transaction(amount: 900, kind: .transfer),
            TestFixtures.transaction(amount: 40, currency: .usd)
        ]
        let report = try SpendingAnalyticsService().analyze(rows, date: date, calendar: calendar)
        let eur = try #require(report.currencies.first { $0.currency == .eur })
        #expect(eur.days.count == calendar.range(of: .day, in: .month, for: date)?.count)
        #expect(eur.days.first { $0.date == calendar.startOfDay(for: date) }?.netSpending.amount == 15)
        #expect(eur.days.first { $0.date == calendar.startOfDay(for: nextDay) }?.netSpending.amount == -3)
        #expect(eur.days.reduce(Decimal.zero) { $0 + $1.netSpending.amount } == eur.current.amount)
        #expect(eur.days.filter { $0.netSpending.amount == 0 }.count == eur.days.count - 2)
        #expect(report.currencies.last?.days.reduce(Decimal.zero) { $0 + $1.netSpending.amount } == 40)
    }

    @Test(arguments: [3, 10])
    func timelineUsesCalendarDaysAcrossDaylightSaving(_ month: Int) throws {
        var calendar = TestFixtures.calendar
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: 15)))
        let report = try SpendingAnalyticsService().analyze([TestFixtures.transaction(amount: 1, date: date)], date: date, calendar: calendar)
        let days = try #require(report.currencies.first?.days)
        #expect(days.count == 31)
        #expect(Set(days.map(\.date)).count == 31)
        #expect(days.allSatisfy { calendar.component(.hour, from: $0.date) == 0 })
        #expect(days.map { calendar.component(.day, from: $0.date) } == Array(1...31))
    }

    @Test func drilldownMatchesExactSavedGroupsAndIncludesOnlyReportContributors() throws {
        let calendar = TestFixtures.calendar
        let date = TestFixtures.date
        let interval = try #require(calendar.dateInterval(of: .month, for: date))
        func row(_ merchant: String, kind: Transaction.Kind = .expense, currency: Currency = .eur,
                 date: Date = date, category: FinAI.Category = .shopping) throws -> Transaction {
            try Transaction(id: UUID(), accountID: UUID(), date: date, merchant: merchant,
                            rawDescription: "Shop", money: Money(amount: 10, currency: currency),
                            direction: kind == .refund || kind == .income ? .credit : .debit,
                            kind: kind, category: category, source: .demo)
        }
        let expense = try row("Shop", date: interval.start)
        let refund = try row("Shop", kind: .refund, date: interval.end.addingTimeInterval(-1))
        let other = try row("Shop Outlet")
        let rows = try [expense, refund, other, row("shop"), row("Shop", kind: .income),
                        row("Shop", kind: .transfer), row("Shop", currency: .usd),
                        row("Shop", date: interval.end), row("Shop", date: interval.start.addingTimeInterval(-1)),
                        row("Shop", category: .groceries)]
        let snapshot = FinanceSnapshot(accounts: [], transactions: rows)
        let merchant = SpendingDrilldown(month: date, currency: .eur, group: .merchant("Shop"))
        let matches = merchant.transactions(in: snapshot, calendar: calendar)
        #expect(matches.count == 3)
        #expect(matches.contains(refund))
        #expect(matches.contains(other) == false)
        let category = SpendingDrilldown(month: date, currency: .eur, group: .category(.shopping))
        #expect(category.transactions(in: snapshot, calendar: calendar).count == 4)
        let total = SpendingDrilldown(month: date, currency: .eur)
        #expect(total.transactions(in: snapshot, calendar: calendar).count == 5)
    }
}
