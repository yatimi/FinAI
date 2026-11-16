//
//  BudgetPersistenceTests.swift
//  FinAITests
//
//  Created by Tommy on 09.10.26.
//

import Foundation
import SwiftData
import Testing
@testable import FinAI

extension PersistenceTests {
    struct BudgetPersistenceTests {
        @Test func migratesVersionFiveAndPreservesGoalsAndTransactionsAcrossReopen() async throws {
            let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appending(path: "Finance.store")
            let batch = try ImportFixtures.batch()
            let goal = try SavingsGoal(id: UUID(), name: "Trip", target: Money(amount: 500, currency: .eur),
                                      saved: .zero(.eur), deadline: TestFixtures.date)
            try createVersionFive(at: url, batch: batch, goal: goal)
            let database = FinanceDatabase(storeURL: url)
            #expect(try await database.loadBudgets().isEmpty)
            let before = try await database.load()
            #expect(before.transactions == batch.transactions.sorted { $0.date > $1.date })
            #expect(try await database.loadGoals() == [goal])
            let budget = try makeBudget()
            #expect(try await database.saveBudget(budget, expected: nil) == [budget])
            let reopened = FinanceDatabase(storeURL: url)
            #expect(try await reopened.loadBudgets() == [budget])
            #expect(try await reopened.loadGoals() == [goal])
            #expect(try await reopened.load() == before)
            let edited = try makeBudget(id: budget.id, amount: 800)
            #expect(try await reopened.saveBudget(edited, expected: budget) == [edited])
            await #expect(throws: CategoryBudget.BudgetError.changed) {
                try await database.saveBudget(budget, expected: budget)
            }
            #expect(try await database.loadBudgets() == [edited])
        }

        @Test func duplicateCategoryCurrencyRejectedButOtherCurrencyAllowed() async throws {
            let database = FinanceDatabase(inMemory: true)
            let budget = try makeBudget()
            _ = try await database.saveBudget(budget, expected: nil)
            await #expect(throws: CategoryBudget.BudgetError.duplicate) {
                try await database.saveBudget(makeBudget(), expected: nil)
            }
            let usd = try makeBudget(currency: Currency(code: "USD"))
            #expect(try await database.saveBudget(usd, expected: nil).count == 2)
            await #expect(throws: CategoryBudget.BudgetError.duplicate) {
                try await database.saveBudget(makeBudget(id: usd.id), expected: usd)
            }
            #expect(try await database.loadBudgets() == [budget, usd])
        }

        @Test func invalidAndCancelledSaveLeaveStoreUnchanged() async throws {
            let database = FinanceDatabase(inMemory: true)
            let invalid = try makeBudget(amount: 0)
            await #expect(throws: CategoryBudget.BudgetError.invalidAmount) { try await database.saveBudget(invalid, expected: nil) }
            let budget = try makeBudget()
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    withUnsafeCurrentTask { $0?.cancel() }
                    await #expect(throws: CancellationError.self) { try await database.saveBudget(budget, expected: nil) }
                }
            }
            #expect(try await database.loadBudgets().isEmpty)
        }

        private func makeBudget(id: UUID = UUID(), amount: Decimal = 500, currency: Currency = .eur) throws -> CategoryBudget {
            try CategoryBudget(id: id, category: .groceries, limit: Money(amount: amount, currency: currency))
        }

        private func createVersionFive(at url: URL, batch: ImportBatch, goal: SavingsGoal) throws {
            let schema = Schema([AccountRecord.self, TransactionRecord.self, ImportSessionRecord.self, MerchantRuleRecord.self, GoalRecord.self], version: Schema.Version(5, 0, 0))
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            context.autosaveEnabled = false
            context.insert(AccountRecord(batch.account))
            for transaction in batch.transactions { context.insert(TransactionRecord(transaction)) }
            context.insert(GoalRecord(goal))
            try context.save()
        }
    }
}
