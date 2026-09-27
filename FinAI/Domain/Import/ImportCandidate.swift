//
//  ImportCandidate.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct ImportCandidate: Identifiable, Equatable, Sendable {
    let id: UUID
    let rowNumber: Int
    let date: Date
    let description: String
    let money: Money
    let direction: Transaction.Direction
    var kind: Transaction.Kind
    var category: Category
    let isPossibleDuplicate: Bool

    var allowedKinds: [Transaction.Kind] {
        direction == .debit ? [.expense, .transfer, .adjustment, .unknown] : [.income, .refund, .transfer, .adjustment, .unknown]
    }

    func transaction(accountID: UUID) throws -> Transaction {
        try Transaction(
            id: id, accountID: accountID, date: date, merchant: description.trimmingCharacters(in: .whitespacesAndNewlines),
            rawDescription: description, money: money, direction: direction, kind: kind,
            category: category, source: .imported
        )
    }
}
