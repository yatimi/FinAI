//
//  TransactionClassificationServiceTests.swift
//  FinAI
//
//  Created by Tommy on 27.09.26.
//

import Testing
@testable import FinAI

struct TransactionClassificationServiceTests {
    @Test(arguments: [
        ("  rewe MARKT 123 Berlin  ", "REWE", Category.groceries),
        ("AMZN*Mktp DE 123", "Amazon", .shopping),
        ("DB VERTRIEB GMBH", "Deutsche Bahn", .transport),
        ("amazon-prime DE", "Amazon Prime", .subscriptions),
        ("SPOTIFY AB", "Spotify", .subscriptions),
        ("EDEKA\nBERLIN", "EDEKA", .groceries)
    ])
    func recognizesAliases(description: String, merchant: String, category: Category) {
        let result = TransactionClassificationService().suggest(description: description, kind: .expense)
        #expect(result.merchant == merchant)
        #expect(result.category == category)
    }

    @Test(arguments: ["REWERT", "AMZNISH", "DB", "Transfer to REWE", "PAYPAL *AMZN", "Local Café", ""])
    func doesNotGuessUnknownMerchants(description: String) {
        let result = TransactionClassificationService().suggest(description: description, kind: .expense)
        #expect(result.merchant == description)
        #expect(result.category == .other)
    }

    @Test(arguments: [
        (Transaction.Kind.expense, Category.groceries), (.refund, .groceries),
        (.income, .income), (.transfer, .transfers), (.unknown, .other), (.adjustment, .other)
    ])
    func respectsExplicitTransactionKind(kind: Transaction.Kind, category: Category) {
        let result = TransactionClassificationService().suggest(description: "REWE MARKT", kind: kind)
        #expect(result.merchant == "REWE")
        #expect(result.category == category)
    }

    @Test func longestAliasWinsRegardlessOfCatalogOrder() {
        let general = MerchantKnowledge.Entry(name: "Shop", category: .shopping, aliases: ["Shop"])
        let specific = MerchantKnowledge.Entry(name: "Shop Music", category: .entertainment, aliases: ["Shop Music"])
        for entries in [[general, specific], [specific, general]] {
            let service = TransactionClassificationService(knowledge: MerchantKnowledge(entries: entries))
            #expect(service.suggest(description: "SHOP MUSIC 123", kind: .expense).merchant == "Shop Music")
        }
    }
}
