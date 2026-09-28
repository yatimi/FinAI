//
//  TransactionClassificationService.swift
//  FinAI
//
//  Created by Tommy on 27.09.26.
//

import Foundation

struct TransactionClassificationService: Sendable {
    struct Suggestion: Equatable, Sendable {
        let merchant: String
        let category: Category
    }

    var knowledge: MerchantKnowledge = .standard

    func suggest(description: String, kind: Transaction.Kind) -> Suggestion {
        let match = knowledge.match(description)
        let category: Category
        switch kind {
        case .income: category = .income
        case .transfer: category = .transfers
        case .expense, .refund: category = match?.category ?? .other
        case .adjustment, .unknown: category = .other
        }
        return Suggestion(
            merchant: match?.name ?? description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category
        )
    }
}
