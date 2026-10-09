//
//  FinanceStoreConfiguration.swift
//  FinAI
//
//  Created by Tommy on 03.10.26.
//

import Foundation
import SwiftData

struct FinanceStoreConfiguration: Sendable {
    let inMemory: Bool
    let storeURL: URL?

    init(inMemory: Bool = false, storeURL: URL? = nil) {
        self.inMemory = inMemory
        self.storeURL = storeURL
    }

    func makeContainer() throws -> ModelContainer {
        let schema = Schema([AccountRecord.self, TransactionRecord.self, ImportSessionRecord.self, MerchantRuleRecord.self, GoalRecord.self], version: Schema.Version(5, 0, 0))
        let configuration: ModelConfiguration
        if let storeURL {
            configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
