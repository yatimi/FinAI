//
//  MerchantKnowledge.swift
//  FinAI
//
//  Created by Tommy on 27.09.26.
//

import Foundation

/// A conservative local catalog. Aliases match only at the start of a description,
/// on complete token boundaries, so an incidental mention is not a merchant match.
struct MerchantKnowledge: Sendable {
    struct Entry: Sendable {
        let name: String
        let category: Category
        let aliases: [String]
    }

    let entries: [Entry]

    func match(_ description: String) -> Entry? {
        let tokens = Self.tokens(description)
        guard !tokens.isEmpty else { return nil }
        var best: Entry?
        var longestMatch = 0
        for entry in entries {
            for alias in entry.aliases {
                let aliasTokens = Self.tokens(alias)
                if aliasTokens.count > longestMatch, tokens.starts(with: aliasTokens) {
                    best = entry
                    longestMatch = aliasTokens.count
                }
            }
        }
        return best
    }

    static func tokens(_ text: String) -> [String] {
        text.lowercased(with: Locale(identifier: "en_US_POSIX"))
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }

    static let standard = Self(entries: [
        Entry(name: "REWE", category: .groceries, aliases: ["REWE"]),
        Entry(name: "EDEKA", category: .groceries, aliases: ["EDEKA"]),
        Entry(name: "Lidl", category: .groceries, aliases: ["Lidl"]),
        Entry(name: "ALDI", category: .groceries, aliases: ["ALDI"]),
        Entry(name: "Amazon", category: .shopping, aliases: ["Amazon", "AMZN"]),
        Entry(name: "Amazon Prime", category: .subscriptions, aliases: ["Amazon Prime", "AMZN Prime"]),
        Entry(name: "Deutsche Bahn", category: .transport, aliases: ["Deutsche Bahn", "DB Vertrieb"]),
        Entry(name: "IKEA", category: .shopping, aliases: ["IKEA"]),
        Entry(name: "Netflix", category: .subscriptions, aliases: ["Netflix"]),
        Entry(name: "Spotify", category: .subscriptions, aliases: ["Spotify"])
    ])
}
