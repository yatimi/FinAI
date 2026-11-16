//
//  AssistantFollowUp.swift
//  FinAI
//
//  Created by Tommy on 19.10.26.
//

import Foundation

/// Only complete, explicit period refinements inherit the last successful query.
struct AssistantFollowUp: Sendable {
    func resolve(_ question: String, previous: AssistantQuery?) throws -> AssistantQuery? {
        let text = question.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "?.!"))
            .lowercased()
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let period: AssistantQuery.Period
        switch text {
        case "and last month", "what about last month", "а за прошлый месяц", "а за минулий місяць":
            period = .lastMonth
        case "and this month", "what about this month", "а за этот месяц", "а за цей місяць":
            period = .thisMonth
        default:
            return nil
        }
        guard let previous else { throw AssistantError.unsupportedQuestion }
        return applying(period, to: previous)
    }

    func isRentRefinement(_ question: String) -> Bool {
        ["without rent", "and without rent", "а без аренды", "без аренды", "а без оренди", "без оренди"]
            .contains(AssistantCategoryVocabulary.normalized(question))
    }

    func applying(_ period: AssistantQuery.Period, to previous: AssistantQuery) -> AssistantQuery {
        var query = previous
        query.period = period
        return query
    }
}
