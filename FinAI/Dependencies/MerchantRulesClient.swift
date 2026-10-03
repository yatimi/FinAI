//
//  MerchantRulesClient.swift
//  FinAI
//
//  Created by Tommy on 02.10.26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct MerchantRulesClient: Sendable {
    var load: @Sendable () async throws -> [MerchantRule]
    var save: @Sendable (MerchantRule, Bool) async throws -> [MerchantRule]
    var delete: @Sendable (UUID) async throws -> [MerchantRule]

    static func live(database: FinanceDatabase) -> Self {
        Self(load: { try await database.loadMerchantRules() },
             save: { try await database.saveMerchantRule($0, replacingExisting: $1) },
             delete: { try await database.deleteMerchantRule($0) })
    }
}

extension MerchantRulesClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var merchantRulesClient: MerchantRulesClient {
        get { self[MerchantRulesClient.self] }
        set { self[MerchantRulesClient.self] = newValue }
    }
}
