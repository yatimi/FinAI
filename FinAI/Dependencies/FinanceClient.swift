//
//  FinanceClient.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct FinanceClient: Sendable {
    var load: @Sendable (_ date: Date, _ calendar: Calendar) async throws -> FinanceOverview
    var addDemo: @Sendable (_ date: Date, _ calendar: Calendar) async throws -> FinanceOverview

    var editTransaction: @Sendable (_ expected: Transaction, _ replacement: Transaction, _ date: Date, _ calendar: Calendar) async throws -> FinanceOverview

    static func live(database: FinanceDatabase) -> Self {
        Self(
            load: { date, calendar in
                try await FinanceOverview.make(snapshot: database.load(), date: date, calendar: calendar)
            },
            addDemo: { date, calendar in
                try await FinanceOverview.make(
                    snapshot: database.addDemo(referenceDate: date, calendar: calendar), date: date, calendar: calendar
                )
            },
            editTransaction: { expected, replacement, date, calendar in
                try await database.editTransaction(expected: expected, replacement: replacement, date: date, calendar: calendar)
            }
        )
    }
}

extension FinanceClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var financeClient: FinanceClient {
        get { self[FinanceClient.self] }
        set { self[FinanceClient.self] = newValue }
    }
}
