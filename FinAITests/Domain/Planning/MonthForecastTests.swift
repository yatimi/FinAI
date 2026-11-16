//
//  MonthForecastTests.swift
//  FinAITests
//
//  Created by Tommy on 23.10.26.
//

import Foundation
import Testing
@testable import FinAI

struct MonthForecastTests {
    private let calendar = TestFixtures.calendar

    @Test func combinesRecordedAmountsWithHistoricalDailyExpensesAndIncome() throws {
        let rows = [try row(310, "2026-08-10"), try row(3000, "2026-08-01", kind: .income),
                    try row(100, "2026-09-02"), try row(20, "2026-09-03", kind: .refund),
                    try row(1000, "2026-09-01", kind: .income)]
        let report = try forecast(rows, on: "2026-09-15")
        let result = try #require(report.currencies.first?.projection)
        #expect(report.remainingDays == 15)
        #expect(result.remainingVariableExpenses.amount == 150)
        #expect(result.remainingIncome.amount == 2000)
        #expect(result.expenses.amount == 250)
        #expect(result.netSpending.amount == 230)
        #expect(result.income.amount == 3000)
        #expect(result.netFlow.amount == 2770)
    }

    @Test func schedulesWeeklyOccurrencesWithoutAlsoAveragingThem() throws {
        let account = UUID()
        let recurring = try ["2026-08-20", "2026-08-27", "2026-09-03"].map { try row(10, $0, account: account) }
        let report = try forecast(recurring + [row(310, "2026-08-10")], on: "2026-09-05")
        let result = try #require(report.currencies.first?.projection)
        #expect(result.remainingRecurringExpenses.amount == 30) // September 10, 17, 24.
        #expect(result.remainingVariableExpenses.amount == 250)
        #expect(result.expenses.amount == 290)
    }

    @Test func monthlyOccurrencesKeepTheirOriginalMonthEndAnchor() throws {
        let account = UUID()
        let rows = try ["2026-05-31", "2026-06-30", "2026-07-31"].map { try row(100, $0, account: account) }
        let result = try #require(forecast(rows, on: "2026-08-15").currencies.first?.projection)
        #expect(result.remainingRecurringExpenses.amount == 100)
        #expect(result.remainingVariableExpenses.amount == 0)
        #expect(result.expenses.amount == 100)
    }

    @Test func postedRecurringPaymentIsCountedOnce() throws {
        let account = UUID()
        let rows = try ["2026-06-20", "2026-07-20", "2026-08-20", "2026-09-20"].map { try row(100, $0, account: account) }
        let report = try forecast(rows, on: "2026-09-20")
        let result = try #require(report.currencies.first?.projection)
        #expect(result.remainingRecurringExpenses.amount == 0)
        #expect(result.remainingVariableExpenses.amount == 0)
        #expect(result.expenses.amount == 100)
    }

    @Test func sameMerchantInTwoAccountsRetainsBothUpcomingPayments() throws {
        var rows: [Transaction] = []
        for account in [UUID(), UUID()] {
            rows += try ["2026-04-20", "2026-05-20", "2026-06-20"].map { try row(100, $0, account: account) }
        }
        let result = try #require(forecast(rows, on: "2026-07-15").currencies.first?.projection)
        #expect(result.remainingRecurringExpenses.amount == 200)
        #expect(result.remainingVariableExpenses.amount == 0)
    }

    @Test func annualPaymentsUseTheirExpectedDateWhenTheCurrencyHasRecentHistory() throws {
        let account = UUID()
        let annual = try ["2023-01-20", "2024-01-20", "2025-01-20"].map { try row(100, $0, account: account) }
        let rows = try annual + [row(31, "2025-12-10")]
        let result = try #require(forecast(rows, on: "2026-01-15").currencies.first?.projection)
        #expect(result.remainingRecurringExpenses.amount == 100)
        #expect(result.remainingVariableExpenses.amount == 16)
    }

    @Test func stalePatternsAreNotAdvancedPastMissingPayments() throws {
        let account = UUID()
        let rows = try ["2026-06-01", "2026-07-01", "2026-08-01"].map { try row(31, $0, account: account) }
        let result = try #require(forecast(rows, on: "2026-09-05").currencies.first?.projection)
        #expect(result.remainingRecurringExpenses.amount == 0)
        #expect(result.remainingVariableExpenses.amount == 25)
    }

    @Test func currenciesAreSeparateAndMissingHistoryIsUnavailable() throws {
        let rows = [try row(310, "2026-08-02"), try row(620, "2026-08-02", currency: .usd),
                    try row(25, "2026-09-02", currency: .uah)]
        let report = try forecast(rows, on: "2026-09-15")
        #expect(report.currencies.map(\.id) == ["EUR", "UAH", "USD"])
        #expect(report.currencies[0].projection?.expenses.amount == 150)
        #expect(report.currencies[1].projection == nil)
        #expect(report.currencies[1].recorded.expenses.amount == 25)
        #expect(report.currencies[2].projection?.expenses.amount == 300)
    }

    @Test func futureRecordsAndNonCashFlowKindsCannotChangeForecast() throws {
        let basis = [try row(310, "2026-08-01")]
        let ignored = [try row(999, "2026-09-16"), try row(999, "2026-10-01", kind: .income),
                       try row(999, "2026-08-01", kind: .transfer), try row(999, "2026-09-01", kind: .unknown),
                       try row(999, "2026-09-01", kind: .adjustment)]
        #expect(try forecast(basis + ignored, on: "2026-09-15") == forecast(basis, on: "2026-09-15"))
    }

    @Test func refundsAreRecordedOnlyAndNeverBecomePredictedIncome() throws {
        let rows = [try row(31, "2026-08-01"), try row(1000, "2026-08-03", kind: .refund),
                    try row(100, "2026-09-01", kind: .refund)]
        let result = try #require(forecast(rows, on: "2026-09-15").currencies.first?.projection)
        #expect(result.remainingVariableExpenses.amount == 15)
        #expect(result.netSpending.amount == -85)
        #expect(result.income.amount == 0)
        #expect(result.netFlow.amount == 85)
    }

    @Test func lastDayHasNoAssumedRemainingIncomeOrExpenses() throws {
        let rows = [try row(310, "2026-08-01"), try row(3000, "2026-08-02", kind: .income),
                    try row(5, "2026-09-30"), try row(100, "2026-09-02", kind: .income)]
        let report = try forecast(rows, on: "2026-09-30")
        let result = try #require(report.currencies.first?.projection)
        #expect(report.remainingDays == 0)
        #expect(result.expenses.amount == 5)
        #expect(result.income.amount == 100)
        #expect(result.netFlow.amount == 95)
    }

    @Test func incomeAboveHistoryIsNeverReduced() throws {
        let rows = [try row(100, "2026-08-01", kind: .income), try row(200, "2026-09-01", kind: .income)]
        let result = try #require(forecast(rows, on: "2026-09-15").currencies.first?.projection)
        #expect(result.income.amount == 200)
        #expect(result.remainingIncome.amount == 0)
    }

    @Test func emptyAndOlderHistoryDoNotFabricateACurrentForecast() throws {
        #expect(try forecast([], on: "2026-09-15").currencies.isEmpty)
        #expect(try forecast([row(100, "2026-07-01")], on: "2026-09-15").currencies.isEmpty)
        let report = try forecast([row(100, "2026-09-01")], on: "2026-09-15")
        #expect(report.currencies.first?.projection == nil)
    }

    @Test(arguments: [("2024-03-01", "2024-02-01", 29, 30),
                      ("2026-01-01", "2025-12-01", 31, 30)])
    func leapYearAndYearBoundaryUseCalendarDays(on: String, basis: String, total: Int, remaining: Int) throws {
        let result = try #require(forecast([row(Decimal(total), basis)], on: on).currencies.first?.projection)
        #expect(result.remainingVariableExpenses.amount == Decimal(remaining))
    }

    @Test func daylightSavingUsesCalendarDaysInsteadOfHours() throws {
        var berlin = Calendar(identifier: .gregorian)
        berlin.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        let now = try #require(berlin.date(from: DateComponents(year: 2026, month: 3, day: 28, hour: 12)))
        let rows = [try row(280, "2026-02-10")]
        let report = try MonthForecastService().forecast(rows, on: now, calendar: berlin)
        #expect(report.remainingDays == 3)
        #expect(report.currencies.first?.projection?.expenses.amount == 30)
    }

    @Test func repeatingDecimalEstimateRoundsOnceToCurrencyPrecision() throws {
        let result = try #require(forecast([row(1, "2026-08-01")], on: "2026-09-15").currencies.first?.projection)
        #expect(result.remainingVariableExpenses.amount == Decimal(string: "0.48"))
    }

    @Test func overflowFailsInsteadOfPublishingPartialOrRoundedTotals() throws {
        let large = Decimal.greatestFiniteMagnitude
        #expect(throws: ValidationError.arithmeticFailure) {
            try forecast([row(large, "2026-08-01")], on: "2026-09-01")
        }
    }

    private func forecast(_ rows: [Transaction], on day: String) throws -> MonthForecast {
        try MonthForecastService().forecast(rows, on: date(day), calendar: calendar)
    }

    private func date(_ value: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return try #require(formatter.date(from: value))
    }

    private func row(_ amount: Decimal, _ day: String, kind: Transaction.Kind = .expense,
                     currency: Currency = .eur, account: UUID = UUID()) throws -> Transaction {
        try TestFixtures.transaction(amount: amount, currency: currency, kind: kind, date: date(day), accountID: account)
    }
}
