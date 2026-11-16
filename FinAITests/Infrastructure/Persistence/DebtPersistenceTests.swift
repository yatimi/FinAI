//
//  DebtPersistenceTests.swift
//  FinAITests
//
//  Created by Tommy on 25.10.26.
//

import Foundation
import SwiftData
import Testing
@testable import FinAI

extension PersistenceTests {
    struct DebtPersistenceTests {
        @Test func migratesVersionSixAndPreservesExistingDataAndRepaymentPrecision() async throws {
            let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appending(path: "Finance.store")
            let batch = try ImportFixtures.batch()
            let goal = try SavingsGoal(id: UUID(), name: "Trip", target: Money(amount: 500, currency: .eur), saved: .zero(.eur), deadline: TestFixtures.date)
            let budget = try CategoryBudget(id: UUID(), category: .groceries, limit: Money(amount: 100, currency: .eur))
            try createVersionSix(at: url, batch: batch, goal: goal, budget: budget)
            let database = FinanceDatabase(storeURL: url)
            let before = try await database.load()
            #expect(try await database.loadDebts(date: TestFixtures.date, calendar: TestFixtures.calendar).isEmpty)
            let debt = try makeDebt()
            _ = try await database.saveDebt(debt, expected: nil, date: TestFixtures.date, calendar: TestFixtures.calendar)
            let amount = try Money(amount: #require(Decimal(string: "23.4567890123456789")), currency: .eur)
            let repayment = DebtRepayment(id: UUID(), amount: amount, date: TestFixtures.date)
            let updated = try DebtPlanningService().adding(repayment, to: debt, on: TestFixtures.date, calendar: TestFixtures.calendar)
            _ = try await database.saveDebt(updated, expected: debt, date: TestFixtures.date, calendar: TestFixtures.calendar)
            let reopened = FinanceDatabase(storeURL: url)
            #expect(try await reopened.loadDebts(date: TestFixtures.date, calendar: TestFixtures.calendar) == [updated])
            #expect(try await reopened.loadGoals() == [goal])
            #expect(try await reopened.loadBudgets() == [budget])
            #expect(try await reopened.load() == before)
            #expect(before.transactions == batch.transactions.sorted { $0.date > $1.date })
            await #expect(throws: PersonalDebt.DebtError.changed) {
                try await database.saveDebt(updated, expected: debt, date: TestFixtures.date, calendar: TestFixtures.calendar)
            }
        }

        @Test func rejectsDuplicateCreationOverpaymentAndCancellationAtomically() async throws {
            let database = FinanceDatabase(inMemory: true)
            let debt = try makeDebt()
            _ = try await database.saveDebt(debt, expected: nil, date: TestFixtures.date, calendar: TestFixtures.calendar)
            await #expect(throws: PersonalDebt.DebtError.changed) {
                try await database.saveDebt(debt, expected: nil, date: TestFixtures.date, calendar: TestFixtures.calendar)
            }
            var overpaid = debt
            overpaid.repayments = [try DebtRepayment(id: UUID(), amount: Money(amount: 101, currency: .eur), date: TestFixtures.date)]
            let invalid = overpaid
            await #expect(throws: PersonalDebt.DebtError.overpayment) {
                try await database.saveDebt(invalid, expected: debt, date: TestFixtures.date, calendar: TestFixtures.calendar)
            }
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    withUnsafeCurrentTask { $0?.cancel() }
                    await #expect(throws: CancellationError.self) {
                        try await database.saveDebt(debt, expected: debt, date: TestFixtures.date, calendar: TestFixtures.calendar)
                    }
                }
            }
            #expect(try await database.loadDebts(date: TestFixtures.date, calendar: TestFixtures.calendar) == [debt])
        }

        @Test func backdatedRepaymentsHaveStableOrderAndStaleWritersCannotOverwriteHistory() async throws {
            let database = FinanceDatabase(inMemory: true)
            let date = TestFixtures.date
            let calendar = TestFixtures.calendar
            let start = try #require(calendar.date(byAdding: .day, value: -10, to: date))
            let debt = try PersonalDebt(id: UUID(), person: "Alex", direction: .iOwe,
                                       principal: Money(amount: 100, currency: .eur), date: start, dueDate: nil)
            _ = try await database.saveDebt(debt, expected: nil, date: date, calendar: calendar)
            let first = try DebtRepayment(id: UUID(), amount: Money(amount: 10, currency: .eur), date: date)
            let updated = try DebtPlanningService().adding(first, to: debt, on: date, calendar: calendar)
            _ = try await database.saveDebt(updated, expected: debt, date: date, calendar: calendar)
            let second = try DebtRepayment(id: UUID(), amount: Money(amount: 20, currency: .eur), date: start)
            let backdated = try DebtPlanningService().adding(second, to: updated, on: date, calendar: calendar)
            let saved = try await database.saveDebt(backdated, expected: updated, date: date, calendar: calendar)
            #expect(saved.first?.repayments == [second, first])
            #expect(try await database.loadDebts(date: date, calendar: calendar) == saved)
            await #expect(throws: PersonalDebt.DebtError.changed) {
                try await database.saveDebt(backdated, expected: updated, date: date, calendar: calendar)
            }
            #expect(try await database.loadDebts(date: date, calendar: calendar) == saved)
        }

        @Test func rejectsChangingPrincipalWhenAppendingRepayment() async throws {
            let database = FinanceDatabase(inMemory: true)
            let debt = try makeDebt()
            let date = TestFixtures.date
            let calendar = TestFixtures.calendar
            _ = try await database.saveDebt(debt, expected: nil, date: date, calendar: calendar)
            let repayment = try DebtRepayment(id: UUID(), amount: Money(amount: 10, currency: .eur), date: date)
            let edited = try PersonalDebt(id: debt.id, person: debt.person, direction: debt.direction,
                                         principal: Money(amount: 200, currency: .eur), date: date, dueDate: nil, repayments: [repayment])
            await #expect(throws: PersonalDebt.DebtError.invalid) {
                try await database.saveDebt(edited, expected: debt, date: date, calendar: calendar)
            }
            #expect(try await database.loadDebts(date: date, calendar: calendar) == [debt])
        }

        private func makeDebt() throws -> PersonalDebt {
            try PersonalDebt(id: UUID(), person: "Alex", direction: .owedToMe, principal: Money(amount: 100, currency: .eur), date: TestFixtures.date, dueDate: nil)
        }

        private func createVersionSix(at url: URL, batch: ImportBatch, goal: SavingsGoal, budget: CategoryBudget) throws {
            let schema = Schema([AccountRecord.self, TransactionRecord.self, ImportSessionRecord.self, MerchantRuleRecord.self, GoalRecord.self, BudgetRecord.self], version: Schema.Version(6, 0, 0))
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            context.autosaveEnabled = false
            context.insert(AccountRecord(batch.account))
            for transaction in batch.transactions { context.insert(TransactionRecord(transaction)) }
            context.insert(GoalRecord(goal)); context.insert(BudgetRecord(budget))
            try context.save()
        }
    }
}
