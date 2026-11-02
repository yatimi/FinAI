//
//  AssistantCategoryVocabulary.swift
//  FinAI
//
//  Created by Tommy on 30.10.26.
//

import Foundation

/// Explicit category names only. Rent is not an alias for all housing expenses.
struct AssistantCategoryVocabulary {
    static let categories = Category.allCases.filter { $0 != .income && $0 != .transfers }

    static func aliases(for category: Category) -> [String] {
        switch category {
        case .groceries: ["groceries", "grocery", "продукты", "продуктів", "продукти"]
        case .restaurants: ["restaurants", "рестораны", "ресторани"]
        case .transport: ["transport", "транспорт"]
        case .shopping: ["shopping", "покупки", "покупок"]
        case .housing: ["housing", "жилье", "жильё", "житло"]
        case .utilities: ["utilities", "коммунальные услуги", "комунальні послуги"]
        case .health: ["health", "здоровье", "здоровʼя", "здоров'я"]
        case .entertainment: ["entertainment", "развлечения", "розваги"]
        case .subscriptions: ["subscriptions", "подписки", "підписки"]
        case .travel: ["travel", "путешествия", "подорожі"]
        case .family: ["family", "семья", "семью", "сімʼя", "сім'ю"]
        case .other: ["other", "другое", "інше"]
        case .income, .transfers: []
        }
    }

    static func normalized(_ text: String) -> String {
        text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "?.!"))
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    static func mentioned(in question: String) -> Set<Category> {
        let tokens = question.lowercased().components(separatedBy: .punctuationCharacters)
            .joined(separator: " ").split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let padded = " " + tokens + " "
        return Set(categories.filter { category in
            aliases(for: category).contains { alias in
                let words = alias.components(separatedBy: .punctuationCharacters).joined(separator: " ")
                return padded.contains(" " + words + " ")
            }
        })
    }
}
