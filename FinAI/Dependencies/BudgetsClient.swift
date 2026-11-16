//
//  BudgetsClient.swift
//  FinAI
//
//  Created by Tommy on 09.10.26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct BudgetsClient: Sendable {
    var load: @Sendable () async throws -> [CategoryBudget]
    var save: @Sendable (CategoryBudget, CategoryBudget?) async throws -> [CategoryBudget]

    static func live(database: FinanceDatabase) -> Self {
        Self(load: { try await database.loadBudgets() }, save: { try await database.saveBudget($0, expected: $1) })
    }
}

extension BudgetsClient: TestDependencyKey { static let testValue = Self() }

extension DependencyValues {
    var budgetsClient: BudgetsClient {
        get { self[BudgetsClient.self] }
        set { self[BudgetsClient.self] = newValue }
    }
}
