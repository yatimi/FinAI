//
//  MerchantRule.swift
//  FinAI
//
//  Created by Tommy on 02.10.26.
//

import Foundation

struct MerchantRule: Equatable, Identifiable, Sendable {
    enum MatchMode: String, CaseIterable, Codable, Sendable { case exact, prefix }
    enum RuleError: Error, Equatable { case invalid, conflict, missing }

    let id: UUID
    var pattern: String
    var matchMode: MatchMode
    var kind: Transaction.Kind
    var merchant: String
    var category: Category

    func validate() throws {
        guard !MerchantKnowledge.tokens(pattern).isEmpty, pattern.count <= 500,
              !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              merchant.count <= 200 else { throw RuleError.invalid }
    }

    func matches(description: String, kind: Transaction.Kind) -> Bool {
        guard self.kind == kind else { return false }
        let patternTokens = MerchantKnowledge.tokens(pattern)
        let descriptionTokens = MerchantKnowledge.tokens(description)
        guard !patternTokens.isEmpty else { return false }
        return matchMode == .exact ? descriptionTokens == patternTokens : descriptionTokens.starts(with: patternTokens)
    }

    func conflicts(with other: Self) -> Bool {
        kind == other.kind && matchMode == other.matchMode && MerchantKnowledge.tokens(pattern) == MerchantKnowledge.tokens(other.pattern)
    }

}
