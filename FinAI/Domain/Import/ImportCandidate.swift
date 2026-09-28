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
    var merchant: String
    var kind: Transaction.Kind
    var category: Category
    let isPossibleDuplicate: Bool

    var allowedKinds: [Transaction.Kind] {
        direction == .debit ? [.expense, .transfer, .adjustment, .unknown] : [.income, .refund, .transfer, .adjustment, .unknown]
    }

    func transaction(accountID: UUID) throws -> Transaction {
        let merchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !merchant.isEmpty else { throw ImportError.missingMerchant }
        return try Transaction(
            id: id, accountID: accountID, date: date, merchant: merchant,
            rawDescription: description, money: money, direction: direction, kind: kind,
            category: category, source: .imported
        )
    }
}
