//
//  GoalsClient.swift
//  FinAI
//
//  Created by Tommy on 08.10.26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct GoalsClient: Sendable {
    var load: @Sendable () async throws -> [SavingsGoal]
    var save: @Sendable (SavingsGoal, SavingsGoal?) async throws -> [SavingsGoal]

    static func live(database: FinanceDatabase) -> Self {
        Self(load: { try await database.loadGoals() }, save: { try await database.saveGoal($0, expected: $1) })
    }
}

extension GoalsClient: TestDependencyKey { static let testValue = Self() }

extension DependencyValues {
    var goalsClient: GoalsClient {
        get { self[GoalsClient.self] }
        set { self[GoalsClient.self] = newValue }
    }
}
