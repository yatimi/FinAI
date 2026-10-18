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

    func validated(question: String) throws -> AssistantQuery {
        guard period != .unsupported, operation != .unsupported else { throw AssistantError.unsupportedQuestion }
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
        return AssistantQuery(kind: kind, period: period == .thisMonth ? .thisMonth : .lastMonth,
                              merchant: name.isEmpty ? nil : name)
    }
}
