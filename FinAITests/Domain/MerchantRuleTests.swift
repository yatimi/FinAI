//
//  MerchantRuleTests.swift
//  FinAITests
//
//  Created by Tommy on 02.10.26.
//

import Foundation
import Testing
@testable import FinAI

struct MerchantRuleTests {
    private func rule(_ pattern: String, mode: MerchantRule.MatchMode = .exact, merchant: String = "My shop") -> MerchantRule {
        MerchantRule(id: UUID(), pattern: pattern, matchMode: mode, kind: .expense, merchant: merchant, category: .family)
    }

    @Test func exactMatchingIsNormalizedButDoesNotIgnoreReferences() {
        let rule = rule("REWE MARKT 123")
        #expect(rule.matches(description: " rewe*MARKT 123 ", kind: .expense))
        #expect(rule.matches(description: "REWE MARKT 124", kind: .expense) == false)
        #expect(rule.matches(description: "REWE MARKT 123 EXTRA", kind: .expense) == false)
        #expect(rule.matches(description: "REWE MARKT 123", kind: .refund) == false)
    }

    @Test func prefixUsesWholeTokensAndUserRulesOverrideCatalog() {
        let service = TransactionClassificationService(rules: [rule("REWE", mode: .prefix)])
        #expect(service.suggest(description: "REWE MARKT 123", kind: .expense).category == .family)
        #expect(service.suggest(description: "REWEX", kind: .expense).merchant == "REWEX")
        #expect(service.suggest(description: "REWE", kind: .income).category == .income)
    }

    @Test func exactThenLongestPrefixWinsRegardlessOfInputOrder() {
        let broad = rule("REWE", mode: .prefix, merchant: "Broad")
        let narrow = rule("REWE MARKT", mode: .prefix, merchant: "Narrow")
        let exact = rule("REWE MARKT 123", merchant: "Exact")
        for rules in [[broad, narrow, exact], [exact, narrow, broad]] {
            let service = TransactionClassificationService(rules: rules)
            #expect(service.suggest(description: "REWE MARKT 123", kind: .expense).merchant == "Exact")
            #expect(service.suggest(description: "REWE MARKT 456", kind: .expense).merchant == "Narrow")
        }
    }

    @Test(arguments: ["", "  ", "***", String(repeating: "a", count: 501)])
    func invalidPatternsAreRejected(pattern: String) {
        #expect(throws: MerchantRule.RuleError.invalid) { try rule(pattern).validate() }
    }

    @Test func emptyMerchantIsRejectedAndEquivalentPatternsConflict() {
        #expect(throws: MerchantRule.RuleError.invalid) { try rule("Shop", merchant: "  ").validate() }
        #expect(rule("REWE*MARKT").conflicts(with: rule("rewe markt")))
        #expect(rule("REWE", mode: .exact).conflicts(with: rule("REWE", mode: .prefix)) == false)
    }
}
