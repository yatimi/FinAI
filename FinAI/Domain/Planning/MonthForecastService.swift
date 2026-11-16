//
//  MonthForecastService.swift
//  FinAI
//
//  Created by Tommy on 23.10.26.
//

import Foundation

struct MonthForecastService: Sendable {
    /// An end-of-day scenario based on recorded history, never a balance or affordability estimate.
    func forecast(_ transactions: [Transaction], on date: Date, calendar: Calendar) throws -> MonthForecast {
        guard date.timeIntervalSinceReferenceDate.isFinite,
              let month = calendar.dateInterval(of: .month, for: date),
              let basisStart = calendar.date(byAdding: .month, value: -1, to: month.start),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)),
              let remainingDays = calendar.dateComponents([.day], from: tomorrow, to: month.end).day,
              let basisDays = calendar.dateComponents([.day], from: basisStart, to: month.start).day,
              remainingDays >= 0, basisDays > 0 else { throw ValidationError.invalidSnapshot }
        let observed = transactions.filter { $0.date < tomorrow }
        let relevant = observed.filter { [.expense, .income, .refund].contains($0.kind) }
        let recorded = try FinanceSummaryService().summarize(relevant, from: month.start, to: tomorrow)
        let baseline = relevant.filter { $0.date >= basisStart && $0.date < month.start }
        let currencies = Set((baseline + relevant.filter { $0.date >= month.start }).map { $0.money.currency })
        let detectionDate = max(date, observed.map(\.date).max() ?? date)
        let recurring = RecurringPaymentService().detect(observed, date: detectionDate, calendar: calendar)
            .filter { !$0.isStale }
        let recurringIDs = Set(recurring.flatMap(\.transactionIDs))
        let results = try currencies.sorted { $0.code < $1.code }.map { currency in
            let actual = recorded.first { $0.currency == currency } ?? emptySummary(currency)
            let history = baseline.filter { $0.money.currency == currency }
            guard history.contains(where: { $0.kind == .expense || $0.kind == .income }) else {
                return MonthForecast.CurrencyForecast(recorded: actual, projection: nil)
            }
            let variable = try sum(history.filter { $0.kind == .expense && !recurringIDs.contains($0.id) }, currency: currency)
            let remainingVariable = try prorate(variable, days: remainingDays, basisDays: basisDays)
            var remainingRecurring = Money.zero(currency)
            for payment in recurring where payment.money.currency == currency {
                var index = payment.transactionIDs.count
                // Calculate every occurrence from the original anchor, preserving month-end dates.
                while true {
                    guard let expected = RecurringPaymentService().expectedDay(
                        after: index, from: calendar.startOfDay(for: payment.firstDate),
                        cadence: payment.cadence, calendar: calendar
                    ) else { throw ValidationError.invalidSnapshot }
                    guard expected < month.end else { break }
                    if expected >= tomorrow { remainingRecurring = try remainingRecurring.adding(payment.money) }
                    index += 1
                }
            }
            let historicalIncome = try sum(history.filter { $0.kind == .income }, currency: currency)
            let incomeGap = try historicalIncome.subtracting(actual.income)
            let remainingIncome = try Money(amount: remainingDays == 0 ? 0 : max(0, incomeGap.amount), currency: currency)
            let expenses = try actual.expenses.adding(remainingVariable).adding(remainingRecurring)
            let income = try actual.income.adding(remainingIncome)
            let netSpending = try expenses.subtracting(actual.refunds)
            let projection = try MonthForecast.Projection(
                remainingVariableExpenses: remainingVariable, remainingRecurringExpenses: remainingRecurring,
                remainingIncome: remainingIncome, expenses: expenses, income: income,
                netSpending: netSpending, netFlow: income.subtracting(netSpending)
            )
            return MonthForecast.CurrencyForecast(recorded: actual, projection: projection)
        }
        return MonthForecast(month: month.start, basisMonth: basisStart,
                             throughDay: calendar.startOfDay(for: date), remainingDays: remainingDays, currencies: results)
    }

    private func sum(_ rows: [Transaction], currency: Currency) throws -> Money {
        try rows.reduce(.zero(currency)) { try $0.adding($1.money) }
    }

    private func emptySummary(_ currency: Currency) -> CurrencySummary {
        CurrencySummary(currency: currency, income: .zero(currency), expenses: .zero(currency),
                        refunds: .zero(currency), netSpending: .zero(currency), netFlow: .zero(currency))
    }

    private func prorate(_ money: Money, days: Int, basisDays: Int) throws -> Money {
        var amount = money.amount
        var multiplier = Decimal(days)
        var product = Decimal.zero
        guard NSDecimalMultiply(&product, &amount, &multiplier, .plain) == .noError else {
            throw ValidationError.arithmeticFailure
        }
        var divisor = Decimal(basisDays)
        var quotient = Decimal.zero
        let error = NSDecimalDivide(&quotient, &product, &divisor, .plain)
        guard error == .noError || error == .lossOfPrecision else { throw ValidationError.arithmeticFailure }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .currency
        formatter.currencyCode = money.currency.code
        var rounded = Decimal.zero
        NSDecimalRound(&rounded, &quotient, formatter.maximumFractionDigits, .plain)
        return try Money(amount: rounded, currency: money.currency)
    }
}
