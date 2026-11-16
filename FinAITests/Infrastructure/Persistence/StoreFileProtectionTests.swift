//
//  StoreFileProtectionTests.swift
//  FinAITests
//
//  Created by Tommy on 31.10.26.
//

import Foundation
import SwiftData
import Testing
@testable import FinAI

extension PersistenceTests {
    struct StoreFileProtectionTests {
        @Test func upgradesDirectoryAndSQLiteFilesWithoutChangingContentsOrBackupPolicy() throws {
            let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appending(path: "Finance.store")
            let data = Data("Synthetic local store".utf8)
            for suffix in ["", "-wal", "-shm"] {
                let file = URL(fileURLWithPath: url.path + suffix)
                try data.write(to: file)
                try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: file.path)
            }
            let backupBefore = try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
            try StoreFileProtection().prepareDirectory(for: url)
            try StoreFileProtection().protectStoreFiles(at: url)
            try expectComplete(directory)
            for suffix in ["", "-wal", "-shm"] {
                let file = URL(fileURLWithPath: url.path + suffix)
                try expectComplete(file)
                #expect(try Data(contentsOf: file) == data)
            }
            #expect(try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == backupBefore)
        }

        @Test func existingStoreDataSurvivesProtectionUpgradeAndReopening() async throws {
            let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appending(path: "Finance.store")
            let batch = try ImportFixtures.batch()
            try createUnprotectedStore(at: url, batch: batch)
            let database = FinanceDatabase(storeURL: url)
            let snapshot = try await database.load()
            #expect(snapshot.transactions == batch.transactions.sorted { $0.date > $1.date })
            try expectComplete(directory)
            try expectComplete(url)
            for suffix in ["-wal", "-shm"] {
                let file = URL(fileURLWithPath: url.path + suffix)
                if FileManager.default.fileExists(atPath: file.path) { try expectComplete(file) }
            }
            let reopened = FinanceDatabase(storeURL: url)
            #expect(try await reopened.load() == snapshot)
            #expect(try await reopened.loadGoals().isEmpty)
            try expectComplete(url)
        }

        @Test func unexpectedStoreDirectoryFailsWithoutRemovingData() throws {
            let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appending(path: "Finance.store")
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            let file = url.appending(path: "keep.txt")
            let data = Data("Keep synthetic data".utf8)
            try data.write(to: file)
            #expect(throws: StoreFileProtection.ProtectionError.unexpectedFile) {
                try StoreFileProtection().protectStoreFiles(at: url)
            }
            #expect(try Data(contentsOf: file) == data)
        }

        @Test(.enabled(if: StoreFileProtectionTests.isPhysicalDevice))
        func physicalDeviceReportsCompleteProtectionForStoreAndSidecars() throws {
            let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appending(path: "Finance.store")
            try StoreFileProtection().prepareDirectory(for: url)
            for suffix in ["", "-wal", "-shm"] { try Data("Synthetic".utf8).write(to: URL(fileURLWithPath: url.path + suffix)) }
            try StoreFileProtection().protectStoreFiles(at: url)
            try expectComplete(directory)
            for suffix in ["", "-wal", "-shm"] { try expectComplete(URL(fileURLWithPath: url.path + suffix)) }
        }

        private static var isPhysicalDevice: Bool {
            #if targetEnvironment(simulator)
            false
            #else
            true
            #endif
        }

        private func expectComplete(_ url: URL) throws {
            #if !targetEnvironment(simulator)
            let value = try FileManager.default.attributesOfItem(atPath: url.path)[.protectionKey]
            #expect((value as? FileProtectionType) == .complete || (value as? String) == FileProtectionType.complete.rawValue)
            #endif
        }

        private func createUnprotectedStore(at url: URL, batch: ImportBatch) throws {
            let schema = Schema([AccountRecord.self, TransactionRecord.self, ImportSessionRecord.self, MerchantRuleRecord.self,
                                 GoalRecord.self, BudgetRecord.self, DebtRecord.self, DebtRepaymentRecord.self], version: Schema.Version(7, 0, 0))
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            context.autosaveEnabled = false
            context.insert(AccountRecord(batch.account))
            for transaction in batch.transactions { context.insert(TransactionRecord(transaction)) }
            try context.save()
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: url.path)
        }
    }
}
