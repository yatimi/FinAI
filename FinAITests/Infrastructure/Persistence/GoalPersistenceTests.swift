//
//  GoalPersistenceTests.swift
//  FinAITests
//
//  Created by Tommy on 08.10.26.
//

import Foundation
import SwiftData
import Testing
@testable import FinAI

extension PersistenceTests {
    struct GoalPersistenceTests {
        @Test func migratesVersionFourAndPreservesTransactionsAndGoalsAcrossReopen() async throws {
            let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appending(path: "Finance.store")
            let batch = try ImportFixtures.batch()
            try createVersionFour(at: url, batch: batch)
            let database = FinanceDatabase(storeURL: url)
            #expect(try await database.loadGoals().isEmpty)
            let before = try await database.load()
            #expect(before.transactions == batch.transactions.sorted { $0.date > $1.date })
            let goal = try makeGoal()
            #expect(try await database.saveGoal(goal, expected: nil) == [goal])
            let reopened = FinanceDatabase(storeURL: url)
            #expect(try await reopened.loadGoals() == [goal])
            #expect(try await reopened.load() == before)
            let edited = try makeGoal(id: goal.id, saved: 800)
            #expect(try await reopened.saveGoal(edited, expected: goal) == [edited])
            await #expect(throws: SavingsGoal.GoalError.changed) {
                try await database.saveGoal(goal, expected: goal)
            }
            #expect(try await database.loadGoals() == [edited])
        }

        @Test func invalidAndCancelledSaveLeaveStoreUnchanged() async throws {
            let database = FinanceDatabase(inMemory: true)
            let goal = try makeGoal()
            let invalid = SavingsGoal(id: UUID(), name: "", target: goal.target, saved: goal.saved, deadline: goal.deadline)
            await #expect(throws: SavingsGoal.GoalError.invalidName) { try await database.saveGoal(invalid, expected: nil) }
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    withUnsafeCurrentTask { $0?.cancel() }
                    await #expect(throws: CancellationError.self) { try await database.saveGoal(goal, expected: nil) }
                }
            }
            #expect(try await database.loadGoals().isEmpty)
        }

        private func makeGoal(id: UUID = UUID(), saved: Decimal = 500) throws -> SavingsGoal {
            try SavingsGoal(id: id, name: "MacBook", target: Money(amount: 2500, currency: .eur),
                            saved: Money(amount: saved, currency: .eur), deadline: TestFixtures.date)
        }

        private func createVersionFour(at url: URL, batch: ImportBatch) throws {
            let schema = Schema([AccountRecord.self, TransactionRecord.self, ImportSessionRecord.self, MerchantRuleRecord.self], version: Schema.Version(4, 0, 0))
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            context.autosaveEnabled = false
            context.insert(AccountRecord(batch.account))
            for transaction in batch.transactions { context.insert(TransactionRecord(transaction)) }
            try context.save()
        }
    }
}
