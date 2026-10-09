//
//  FinanceDatabase.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import SwiftData

/// Serializes persistence operations. Contexts and records never leave this actor.
actor FinanceDatabase {
    private let configuration: FinanceStoreConfiguration
    private var container: ModelContainer?

    init(inMemory: Bool = false, storeURL: URL? = nil) {
        configuration = FinanceStoreConfiguration(inMemory: inMemory, storeURL: storeURL)
    }

    func load() throws -> FinanceSnapshot {
        try Task.checkCancellation()
        return try FinanceSnapshotStore().load(in: makeContext())
    }

    func addDemo(referenceDate: Date, calendar: Calendar) throws -> FinanceSnapshot {
        try Task.checkCancellation()
        return try DemoSeedStore().addDemo(referenceDate: referenceDate, calendar: calendar, in: makeContext())
    }

    func saveImport(_ batch: ImportBatch) throws {
        try Task.checkCancellation()
        try batch.validate()
        try ImportBatchStore().save(batch, in: makeContext())
    }

    func editTransaction(expected: Transaction, replacement: Transaction, date: Date, calendar: Calendar) throws -> FinanceOverview {
        try Task.checkCancellation()
        return try TransactionEditStore().save(expected: expected, replacement: replacement, date: date, calendar: calendar, in: makeContext())
    }

    func loadMerchantRules() throws -> [MerchantRule] {
        try Task.checkCancellation()
        return try MerchantRuleStore().load(in: makeContext())
    }

    func saveMerchantRule(_ rule: MerchantRule, replacingExisting: Bool) throws -> [MerchantRule] {
        try Task.checkCancellation()
        try rule.validate()
        return try MerchantRuleStore().save(rule, replacingExisting: replacingExisting, in: makeContext())
    }

    func deleteMerchantRule(_ id: UUID) throws -> [MerchantRule] {
        try Task.checkCancellation()
        return try MerchantRuleStore().delete(id, in: makeContext())
    }

    func loadGoals() throws -> [SavingsGoal] {
        try Task.checkCancellation()
        return try GoalStore().load(in: makeContext())
    }

    func saveGoal(_ goal: SavingsGoal, expected: SavingsGoal?) throws -> [SavingsGoal] {
        try Task.checkCancellation()
        try goal.validate()
        return try GoalStore().save(goal, expected: expected, in: makeContext())
    }

    private func makeContext() throws -> ModelContext {
        let container: ModelContainer
        if let existing = self.container {
            container = existing
        } else {
            container = try configuration.makeContainer()
            self.container = container
        }
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }
}
