//
//  DebtsClient.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct DebtsClient: Sendable {
    var load: @Sendable (Date, Calendar) async throws -> [PersonalDebt]
    var save: @Sendable (PersonalDebt, PersonalDebt?, Date, Calendar) async throws -> [PersonalDebt]

    static func live(database: FinanceDatabase) -> Self {
        Self(load: { try await database.loadDebts(date: $0, calendar: $1) },
             save: { try await database.saveDebt($0, expected: $1, date: $2, calendar: $3) })
    }
}

extension DebtsClient: TestDependencyKey { static let testValue = Self() }

extension DependencyValues {
    var debtsClient: DebtsClient {
        get { self[DebtsClient.self] }
        set { self[DebtsClient.self] = newValue }
    }
}
