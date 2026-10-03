//
//  MerchantRuleRecord.swift
//  FinAI
//
//  Created by Tommy on 02.10.26.
//

import Foundation
import SwiftData

@Model
final class MerchantRuleRecord {
    @Attribute(.unique) var id: UUID
    var pattern: String
    var matchMode: String
    var kind: String
    var merchant: String
    var category: String

    init(_ rule: MerchantRule) {
        id = rule.id
        pattern = rule.pattern
        matchMode = rule.matchMode.rawValue
        kind = rule.kind.rawValue
        merchant = rule.merchant
        category = rule.category.rawValue
    }

    func domainValue() throws -> MerchantRule {
        guard let mode = MerchantRule.MatchMode(rawValue: matchMode),
              let kind = Transaction.Kind(rawValue: kind),
              let category = Category(rawValue: category) else { throw MerchantRule.RuleError.invalid }
        let rule = MerchantRule(id: id, pattern: pattern, matchMode: mode, kind: kind, merchant: merchant, category: category)
        try rule.validate()
        return rule
    }
}
