//
//  StatementImportFeatureTests.swift
//  FinAITests
//
//  Created by Tommy on 06.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct StatementImportFeatureTests {
    @Test func readsPDFPreviewsAndSavesOnlyAfterConfirmation() async throws {
        let statement = try StatementFixtures.document()
        let preview = try ImportPreviewService().preview(statement: statement, account: ImportFixtures.account, existing: [], timeZone: .gmt)
        let sessionID = UUID()
        var state = ImportFeature.State(snapshot: .empty, newAccountID: ImportFixtures.account.id)
        state.newAccountName = ImportFixtures.account.name
        state.mapping.currencyCode = "USD"
        let store = TestStore(initialState: state) { ImportFeature() } withDependencies: {
            $0.importClient.readStatement = { _ in statement }
            $0.importClient.previewStatement = { received, account, existing, timeZone in
                #expect(received == statement)
                #expect(account == ImportFixtures.account)
                #expect(existing.isEmpty)
                #expect(timeZone == .gmt)
                return preview
            }
            $0.importClient.save = { batch in
                #expect(batch.sourceName == statement.name)
                #expect(batch.transactions.count == 4)
                #expect(batch.transactions.map(\.money.currency).allSatisfy { $0 == .eur })
                #expect(batch.transactions.first?.rawDescription == statement.entries[0].description)
                #expect(batch.transactions.first?.source == .imported)
            }
            $0.uuid = .constant(sessionID)
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
        }
        await store.send(.fileChosen(URL(fileURLWithPath: "/example.PDF"))) { $0.phase = .reading }
        await store.receive(.statementRead(.success(statement))) {
            $0.phase = .idle
            $0.statement = statement
            $0.mapping.currencyCode = "EUR"
        }
        await store.send(.previewTapped) {
            $0.phase = .previewing
            $0.previewAccount = ImportFixtures.account
            $0.sessionID = sessionID
        }
        await store.receive(.previewResponse(.success(preview))) {
            $0.phase = .idle
            $0.preview = preview
        }
        let last = try #require(preview.candidates.last)
        await store.send(.toggleRow(last.id)) { $0.excludedIDs = [last.id] }
        await store.send(.importTapped) {
            $0.alert = AlertState {
                TextState(.importSelectedTransactions)
            } actions: {
                ButtonState(action: .confirmImport) { TextState(.confirmImport) }
                ButtonState(role: .cancel) { TextState(.cancel) }
            } message: {
                TextState(.importConfirmationMessage(4, 1))
            }
        }
        await store.send(.alert(.presented(.confirmImport))) {
            $0.alert = nil
            $0.phase = .saving
        }
        await store.receive(.saveResponse(.success(ImportFeature.VoidSuccess()))) { $0.phase = .idle }
        await store.receive(.delegate(.didImport))
    }

    @Test func failedPDFClearsPreviousCSVAndShowsSpecificError() async throws {
        var state = ImportFeature.State(snapshot: .empty, newAccountID: UUID())
        state.document = try ImportFixtures.document()
        let store = TestStore(initialState: state) { ImportFeature() } withDependencies: {
            $0.importClient.readStatement = { _ in throw ImportError.statementBalanceMismatch }
        }
        await store.send(.fileChosen(URL(fileURLWithPath: "/example.pdf"))) {
            $0.document = nil
            $0.phase = .reading
        }
        await store.receive(.statementRead(.failure(.statementBalanceMismatch))) {
            $0.phase = .idle
            $0.error = .statementBalanceMismatch
        }
        #expect(store.state.sourceName == nil)
    }

    @Test func replacingPDFWithCSVClearsStatementAndPreservesCurrency() async throws {
        var state = ImportFeature.State(snapshot: .empty, newAccountID: UUID())
        state.statement = try StatementFixtures.document()
        state.mapping.currencyCode = "USD"
        let document = try ImportFixtures.document()
        let store = TestStore(initialState: state) { ImportFeature() } withDependencies: {
            $0.importClient.readFile = { _ in document }
        }
        await store.send(.fileChosen(URL(fileURLWithPath: "/example.csv"))) {
            $0.statement = nil
            $0.phase = .reading
        }
        await store.receive(.fileRead(.success(document))) {
            $0.phase = .idle
            $0.document = document
            $0.mapping = .suggested(for: document)
            $0.mapping.currencyCode = "USD"
        }
    }

    @Test func dismissingImportCancelsPDFReading() async throws {
        let clock = TestClock()
        let statement = try StatementFixtures.document()
        var state = AppFeature.State()
        state.importFlow = ImportFeature.State(snapshot: .empty, newAccountID: UUID())
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.importClient.readStatement = { _ in
                try await clock.sleep(for: .seconds(10))
                return statement
            }
        }
        await store.send(.importFlow(.presented(.fileChosen(URL(fileURLWithPath: "/sample.pdf"))))) {
            $0.importFlow?.phase = .reading
        }
        await store.send(.importFlow(.dismiss)) { $0.importFlow = nil }
        await store.finish()
    }

    @Test(arguments: [false, true])
    func statementCurrencyIsPreservedForNewAndExistingAccounts(useExistingAccount: Bool) throws {
        let dollarAccount = Account(id: UUID(), name: "Dollar account", kind: .bank, currency: .usd)
        var state = ImportFeature.State(snapshot: FinanceSnapshot(accounts: [dollarAccount], transactions: []), newAccountID: UUID())
        let statement = try StatementFixtures.document()
        state.statement = statement
        state.newAccountName = "Euro statement"
        state.mapping.currencyCode = "USD"
        if useExistingAccount { state.selectedAccountID = dollarAccount.id }
        let account = try state.account()
        #expect(account.currency == (useExistingAccount ? .usd : .eur))
        let preview = try ImportPreviewService().preview(statement: statement, account: account, existing: [], timeZone: .gmt)
        #expect(preview.candidates.allSatisfy { $0.money.currency == .eur })
    }
}
