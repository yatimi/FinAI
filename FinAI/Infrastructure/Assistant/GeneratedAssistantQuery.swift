//
//  GeneratedAssistantQuery.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import Foundation
import FoundationModels

@Generable
struct GeneratedAssistantQuery: Sendable {
    @Generable
    enum Operation: Sendable { case spending, comparison, merchant, unsupported }
    @Generable
    enum Period: Sendable { case thisMonth, lastMonth, unsupported }

    @Guide(description: "Use unsupported unless the entire question is supported. No partial answers.")
    var operation: Operation
    @Guide(description: "Only this month or last month. An omitted period means this month. Other periods are unsupported.")
    var period: Period
    @Guide(description: "Exact merchant name from the question for merchant spending only, otherwise an empty string.")
    var merchant: String

    @Guide(description: "For spending or comparison only, use one explicit category raw name from the supported list, otherwise an empty string. Rent is not housing.")
    var category: String = ""

    func validated(question: String) throws -> AssistantQuery {
        guard period != .unsupported, operation != .unsupported else { throw AssistantError.unsupportedQuestion }
        let tokens = question.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
        guard !tokens.contains(where: { ["without", "excluding", "except", "без", "кроме", "окрім"].contains($0) }) else {
            throw AssistantError.unsupportedQuestion
        }
        let name = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let kind: AssistantQuery.Kind
        switch operation {
        case .spending: kind = .spending
        case .comparison: kind = .comparison
        case .merchant: kind = .merchant
        case .unsupported: throw AssistantError.unsupportedQuestion
        }
        guard name.count <= 200, kind == .merchant ? !name.isEmpty : name.isEmpty else {
            throw AssistantError.unsupportedQuestion
        }
        if kind == .merchant {
            guard question.range(of: name, options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX")) != nil else {
                throw AssistantError.unsupportedQuestion
            }
        }
        if kind != .merchant, tokens.contains(where: { ["rent", "аренда", "аренду", "аренды", "оренда", "оренду", "оренди"].contains($0) }) {
            throw AssistantError.unsupportedQuestion
        }
        let categoryName = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedCategory: Category?
        if categoryName.isEmpty { resolvedCategory = nil }
        else {
            guard kind != .merchant, let value = Category(rawValue: categoryName),
                  AssistantCategoryVocabulary.categories.contains(value),
                  AssistantCategoryVocabulary.mentioned(in: question) == [value] else {
                throw AssistantError.unsupportedQuestion
            }
            resolvedCategory = value
        }
        if kind != .merchant, resolvedCategory == nil,
           !AssistantCategoryVocabulary.mentioned(in: question).isEmpty { throw AssistantError.unsupportedQuestion }
        return AssistantQuery(kind: kind, period: period == .thisMonth ? .thisMonth : .lastMonth,
                              merchant: name.isEmpty ? nil : name, category: resolvedCategory)
    }
}
