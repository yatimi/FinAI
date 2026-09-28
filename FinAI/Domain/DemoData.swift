//
//  DemoData.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct DemoData: Sendable {
    func make(referenceDate: Date, calendar: Calendar) throws -> FinanceSnapshot {
        let bank = Account(id: UUID(), name: "Demo current account", kind: .bank, currency: .eur)
        let savings = Account(id: UUID(), name: "Demo savings", kind: .savings, currency: .eur)
        let travel = Account(id: UUID(), name: "Demo travel card", kind: .credit, currency: .usd)
        var transactions: [Transaction] = []
        guard let currentMonth = calendar.dateInterval(of: .month, for: referenceDate)?.start else {
            throw ValidationError.invalidSnapshot
        }
        for offset in -2...0 {
            guard let month = calendar.date(byAdding: .month, value: offset, to: currentMonth) else {
                throw ValidationError.invalidSnapshot
            }
            let entries: [(Int, String, Int, Transaction.Kind, Category)] = [
                (0, "Demo employer", 340000, .income, .income),
                (0, "Demo rent", 105000, .expense, .housing),
                (1, "REWE", 6549, .expense, .groceries),
                (2, "Deutsche Bahn", 6300, .expense, .transport),
                (3, "Spotify", 1299, .expense, .subscriptions),
                (4, "Demo energy", 8900, .expense, .utilities),
                (5, "Demo café", 1870, .expense, .restaurants),
                (6, "Amazon", 24999, .expense, .shopping),
                (7, "Demo pharmacy", 2450, .expense, .health),
                (8, "Demo cinema", 1600, .expense, .entertainment),
                (9, "REWE", 4280, .expense, .groceries),
                (10, "Amazon", 4999, .refund, .shopping),
                (11, "Demo train journey", 7900, .expense, .travel),
                (12, "Demo family gift", 5000, .expense, .family)
            ]
            for (day, merchant, cents, kind, category) in entries {
                guard let date = calendar.date(byAdding: .day, value: day, to: month) else {
                    throw ValidationError.invalidSnapshot
                }
                guard date <= referenceDate else { continue }
                transactions.append(try Transaction(
                    id: UUID(), accountID: bank.id, date: date, merchant: merchant,
                    rawDescription: "Synthetic sample: " + merchant,
                    money: Money(amount: Decimal(cents) / 100, currency: .eur),
                    direction: kind == .expense ? .debit : .credit,
                    kind: kind, category: category, incomeKind: kind == .income ? .salary : nil, source: .demo
                ))
            }
            for (account, direction) in [(bank, Transaction.Direction.debit), (savings, .credit)] {
                transactions.append(try Transaction(
                    id: UUID(), accountID: account.id, date: month, merchant: "Demo savings transfer",
                    rawDescription: "Synthetic transfer between owned accounts",
                    money: Money(amount: 400, currency: .eur), direction: direction,
                    kind: .transfer, category: .transfers, source: .demo
                ))
            }
            transactions.append(try Transaction(
                id: UUID(), accountID: travel.id, date: month, merchant: "Demo hotel",
                rawDescription: "Synthetic USD purchase", money: Money(amount: 120, currency: .usd),
                direction: .debit, kind: .expense, category: .travel, source: .demo
            ))
        }
        return FinanceSnapshot(accounts: [bank, savings, travel], transactions: transactions)
    }
}
