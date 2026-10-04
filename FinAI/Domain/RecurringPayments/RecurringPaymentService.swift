//
//  RecurringPaymentService.swift
//  FinAI
//
//  Created by Tommy on 30.09.26.
//

import Foundation

struct RecurringPaymentService: Sendable {
    /// Conservative exact-amount matching. Irregular or ambiguous groups are omitted.
    func detect(_ transactions: [Transaction], date: Date, calendar: Calendar) -> [RecurringPayment] {
        let expenses = transactions.filter {
            $0.kind == .expense && $0.direction == .debit && $0.money.amount > 0
                && $0.date <= date && !$0.merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let groups = Dictionary(grouping: expenses) {
            RecurringPayment.ID(
                accountID: $0.accountID, merchant: $0.merchant,
                currency: $0.money.currency, amount: $0.money.amount
            )
        }
        return groups.compactMap { id, rows -> RecurringPayment? in
            let sorted = rows.sorted {
                $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date < $1.date
            }
            guard sorted.count >= 3, let first = sorted.first, let last = sorted.last else { return nil }
            let days = sorted.map { calendar.startOfDay(for: $0.date) }
            // Same-day duplicates are ambiguous, even if they have different IDs.
            guard Set(days).count == days.count else { return nil }
            guard let cadence = RecurringPayment.Cadence.allCases.first(where: { cadence in
                days.enumerated().allSatisfy { index, day in
                    guard let expected = expectedDay(after: index, from: days[0], cadence: cadence, calendar: calendar),
                          let difference = calendar.dateComponents([.day], from: expected, to: day).day else { return false }
                    return abs(difference) <= tolerance(for: cadence)
                }
            }),
            let expected = expectedDay(after: days.count, from: days[0], cadence: cadence, calendar: calendar),
            let graceEnd = calendar.date(byAdding: .day, value: tolerance(for: cadence), to: expected)
            else { return nil }
            return RecurringPayment(
                id: id, merchant: first.merchant, money: first.money, cadence: cadence,
                transactionIDs: sorted.map(\.id), firstDate: first.date, lastDate: last.date,
                expectedDate: expected,
                isSubscriptionCandidate: sorted.allSatisfy { $0.category == .subscriptions },
                isStale: calendar.startOfDay(for: date) > graceEnd
            )
        }.sorted {
            if $0.isStale != $1.isStale { return !$0.isStale }
            if $0.expectedDate != $1.expectedDate { return $0.expectedDate < $1.expectedDate }
            if $0.merchant != $1.merchant { return $0.merchant < $1.merchant }
            if $0.id.currency.code != $1.id.currency.code { return $0.id.currency.code < $1.id.currency.code }
            if $0.id.amount != $1.id.amount { return $0.id.amount < $1.id.amount }
            return $0.id.accountID.uuidString < $1.id.accountID.uuidString
        }
    }

    private func tolerance(for cadence: RecurringPayment.Cadence) -> Int {
        cadence == .weekly ? 1 : 3
    }

    private func expectedDay(
        after count: Int, from anchor: Date, cadence: RecurringPayment.Cadence, calendar: Calendar
    ) -> Date? {
        switch cadence {
        case .weekly: calendar.date(byAdding: .day, value: count * 7, to: anchor)
        case .monthly: calendar.date(byAdding: .month, value: count, to: anchor)
        case .yearly: calendar.date(byAdding: .year, value: count, to: anchor)
        }
    }
}
