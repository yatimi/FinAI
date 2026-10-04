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

    var rules: [MerchantRule] = []
    var knowledge: MerchantKnowledge = .standard

    func suggest(description: String, kind: Transaction.Kind) -> Suggestion {
        let rule = rules.filter { $0.matches(description: description, kind: kind) }.sorted {
            if $0.matchMode != $1.matchMode { return $0.matchMode == .exact }
            let left = MerchantKnowledge.tokens($0.pattern).count
            let right = MerchantKnowledge.tokens($1.pattern).count
            return left == right ? $0.id.uuidString < $1.id.uuidString : left > right
        }.first
        if let rule {
            return Suggestion(merchant: rule.merchant.trimmingCharacters(in: .whitespacesAndNewlines), category: rule.category)
        }
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
