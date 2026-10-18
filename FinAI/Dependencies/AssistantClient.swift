//
//  AssistantClient.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct AssistantClient: Sendable {
    var availability: @Sendable (Locale) -> AssistantAvailability = { _ in .notReady }
    var interpret: @Sendable (String, Locale) async throws -> AssistantQuery
    var answer: @Sendable (AssistantQuery, FinanceSnapshot, Date, Calendar) async throws -> AssistantAnswer
}

extension AssistantClient: DependencyKey {
    static let liveValue = Self(
        availability: { OnDeviceQuestionInterpreter().availability(locale: $0) },
        interpret: { try await OnDeviceQuestionInterpreter().interpret($0, locale: $1) },
        answer: { try await calculate($0, snapshot: $1, date: $2, calendar: $3) }
    )
    static let testValue = Self()

    @concurrent
    private static func calculate(_ query: AssistantQuery, snapshot: FinanceSnapshot, date: Date, calendar: Calendar) async throws -> AssistantAnswer {
        try FinancialAssistant().answer(query, snapshot: snapshot, date: date, calendar: calendar)
    }
}

extension DependencyValues {
    var assistantClient: AssistantClient {
        get { self[AssistantClient.self] }
        set { self[AssistantClient.self] = newValue }
    }
}
