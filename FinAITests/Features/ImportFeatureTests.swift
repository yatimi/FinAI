//
//  ImportFeatureTests.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct ImportFeatureTests {
    @Test func correctionsAreConfirmedAndSavedWithoutChangingOriginalDescription() async throws {
        let state = try preparedState()
        let first = try #require(state.preview?.candidates.first)
        let store = TestStore(initialState: state) { ImportFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.importClient.save = { batch in
                let transaction = try #require(batch.transactions.first)
                #expect(transaction.merchant == "Local Café")
                #expect(transaction.category == .restaurants)
                #expect(transaction.rawDescription == first.description)
                #expect(transaction.money == first.money)
                #expect(transaction.kind == first.kind)
            }
        }
        await store.send(.categoryChanged(first.id, .restaurants)) { $0.preview?.candidates[0].category = .restaurants }
        await store.send(.kindChanged(first.id, first.kind))
        await store.send(.merchantChanged(first.id, " Local Café ")) { $0.preview?.candidates[0].merchant = " Local Café " }
        await store.send(.importTapped) { $0.alert = confirmationAlert(count: 2, skipped: 1) }
        await store.send(.alert(.presented(.confirmImport))) {
            $0.alert = nil
            $0.phase = .saving
        }
        await store.receive(.saveResponse(.success(ImportFeature.VoidSuccess()))) { $0.phase = .idle }
        await store.receive(.delegate(.didImport))
    }

    @Test func changingTypeUsesMerchantSuggestionAndRejectsInvalidDirection() async throws {
        var state = try preparedState()
        state.preview?.candidates[0].merchant = "REWE"
        state.preview?.candidates[0].category = .groceries
        let first = try #require(state.preview?.candidates.first)
        let store = TestStore(initialState: state) { ImportFeature() }
        await store.send(.kindChanged(first.id, .income))
        await store.send(.kindChanged(first.id, .transfer)) {
            $0.preview?.candidates[0].kind = .transfer
            $0.preview?.candidates[0].category = .transfers
        }
        await store.send(.kindChanged(first.id, .expense)) {
            $0.preview?.candidates[0].kind = .expense
            $0.preview?.candidates[0].category = .groceries
        }
    }

    @Test func emptyMerchantBlocksConfirmationAndCanBeCorrected() async throws {
        var state = try preparedState()
        state.preview?.candidates[0].merchant = "  "
        let first = try #require(state.preview?.candidates.first)
        let store = TestStore(initialState: state) { ImportFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
        }
        await store.send(.importTapped) { $0.alert = confirmationAlert(count: 2, skipped: 1) }
        await store.send(.alert(.presented(.confirmImport))) {
            $0.alert = nil
            $0.error = .missingMerchant
        }
        await store.send(.merchantChanged(first.id, "Café")) {
            $0.preview?.candidates[0].merchant = "Café"
            $0.error = nil
        }
        #expect(store.state.phase == .idle)
    }

    @Test(arguments: [false, true])
    func replacingFilePreservesDefaultCurrency(useExistingAccount: Bool) async throws {
        let account = Account(id: UUID(), name: "Dollar account", kind: .bank, currency: try Currency(code: "USD"))
        let document = try CSVParser().parse(
            "amount,description,date\n-12.50,Test coffee,2026-09-01",
            name: "replacement.csv"
        )
        var state = ImportFeature.State(
            snapshot: FinanceSnapshot(accounts: [account], transactions: []), newAccountID: UUID()
        )
        state.document = try ImportFixtures.document()
        state.mapping = .suggested(for: try ImportFixtures.document())
        let store = TestStore(initialState: state) { ImportFeature() } withDependencies: {
            $0.importClient.readFile = { _ in document }
        }
        if useExistingAccount {
            await store.send(.binding(.set(\.selectedAccountID, account.id))) {
                $0.selectedAccountID = account.id
                $0.mapping.currencyCode = "USD"
            }
        } else {
            await store.send(.binding(.set(\.newAccountName, account.name))) { $0.newAccountName = account.name }
            await store.send(.binding(.set(\.mapping.currencyCode, "USD"))) { $0.mapping.currencyCode = "USD" }
        }
        await store.send(.fileChosen(URL(fileURLWithPath: "/replacement.csv"))) {
            $0.document = nil
            $0.phase = .reading
        }
        await store.receive(.fileRead(.success(document))) {
            $0.phase = .idle
            $0.document = document
            $0.mapping = .suggested(for: document)
            $0.mapping.currencyCode = "USD"
        }
        let preview = try CSVImportService().preview(
            document: document, mapping: store.state.mapping, account: store.state.account(),
            existing: [], timeZone: .gmt
        )
        let candidate = try #require(preview.candidates.first)
        #expect(candidate.money.currency == account.currency)
        #expect(candidate.money.amount == Decimal(string: "12.50"))
        #expect(preview.issues.isEmpty)
    }

    @Test func readingAndPreviewDoNotWriteData() async throws {
        let document = try ImportFixtures.document()
        let preview = try ImportFixtures.preview()
        let sessionID = UUID()
        var state = ImportFeature.State(snapshot: .empty, newAccountID: ImportFixtures.account.id)
        state.newAccountName = ImportFixtures.account.name
        let store = TestStore(initialState: state) { ImportFeature() } withDependencies: {
            $0.importClient.readFile = { _ in document }
            $0.importClient.preview = { _, _, account, _, _ in
                #expect(account == ImportFixtures.account)
                return preview
            }
            $0.calendar = TestFixtures.calendar
            $0.uuid = .constant(sessionID)
        }
        await store.send(.fileChosen(URL(fileURLWithPath: "/sample.csv"))) { $0.phase = .reading }
        await store.receive(.fileRead(.success(document))) {
            $0.phase = .idle
            $0.document = document
            $0.mapping = .suggested(for: document)
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
        await store.send(.importTapped) { $0.alert = confirmationAlert(count: 2, skipped: 1) }
        await store.send(.alert(.dismiss)) { $0.alert = nil }
    }

    @Test func savesOnlySelectedRowsAfterConfirmation() async throws {
        let state = try preparedState()
        let preview = try #require(state.preview)
        let first = try #require(preview.candidates.first)
        let second = try #require(preview.candidates.last)
        let store = TestStore(initialState: state) { ImportFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.importClient.save = { batch in
                #expect(batch.transactions.map(\.id) == [first.id])
                #expect(batch.rowNumbers == [first.rowNumber])
                #expect(batch.sourceName == "sample.csv")
            }
        }
        await store.send(.toggleRow(second.id)) { $0.excludedIDs = [second.id] }
        await store.send(.importTapped) { $0.alert = confirmationAlert(count: 1, skipped: 2) }
        await store.send(.alert(.presented(.confirmImport))) {
            $0.alert = nil
            $0.phase = .saving
        }
        await store.receive(.saveResponse(.success(ImportFeature.VoidSuccess()))) { $0.phase = .idle }
        await store.receive(.delegate(.didImport))
    }

    @Test func saveFailureKeepsPreviewForRetry() async throws {
        let state = try preparedState()
        let store = TestStore(initialState: state) { ImportFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.importClient.save = { _ in throw ImportError.storageChanged }
        }
        await store.send(.importTapped) { $0.alert = confirmationAlert(count: 2, skipped: 1) }
        await store.send(.alert(.presented(.confirmImport))) {
            $0.alert = nil
            $0.phase = .saving
        }
        await store.receive(.saveResponse(.failure(.storageChanged))) {
            $0.phase = .idle
            $0.error = .storageChanged
        }
        #expect(store.state.preview == state.preview)
        #expect(store.state.sessionID == state.sessionID)
    }

    @Test func dismissingImportCancelsReading() async throws {
        let clock = TestClock()
        let document = try ImportFixtures.document()
        var state = AppFeature.State()
        state.importFlow = ImportFeature.State(snapshot: .empty, newAccountID: UUID())
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.importClient.readFile = { _ in
                try await clock.sleep(for: .seconds(10))
                return document
            }
        }
        await store.send(.importFlow(.presented(.fileChosen(URL(fileURLWithPath: "/sample.csv"))))) {
            $0.importFlow?.phase = .reading
        }
        await store.send(.importFlow(.dismiss)) { $0.importFlow = nil }
        await store.finish()
    }

    @Test func completedImportRefreshesRootAndShowsTransactions() async throws {
        let batch = try ImportFixtures.batch()
        let overview = try FinanceOverview.make(
            snapshot: FinanceSnapshot(accounts: [batch.account], transactions: batch.transactions),
            date: TestFixtures.date, calendar: TestFixtures.calendar
        )
        var state = AppFeature.State()
        state.importFlow = try preparedState()
        state.transactions.query = TransactionQuery(text: "old search", currency: .usd)
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.financeClient.load = { _, _ in overview }
        }
        await store.send(.importFlow(.presented(.delegate(.didImport)))) {
            $0.importFlow = nil
            $0.transactions.query = TransactionQuery()
            $0.selectedTab = .transactions
            $0.isLoading = true
        }
        await store.receive(.response(.success(overview))) {
            $0.isLoading = false
            $0.overview = overview
            $0.transactions.update(snapshot: overview.snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        }
    }

    private func preparedState() throws -> ImportFeature.State {
        var state = ImportFeature.State(snapshot: .empty, newAccountID: ImportFixtures.account.id)
        state.document = try ImportFixtures.document()
        state.preview = try ImportFixtures.preview()
        state.previewAccount = ImportFixtures.account
        state.sessionID = UUID()
        return state
    }

    private func confirmationAlert(count: Int, skipped: Int) -> AlertState<ImportFeature.Action.Alert> {
        AlertState {
            TextState("Import selected transactions?")
        } actions: {
            ButtonState(action: .confirmImport) { TextState("Confirm import") }
            ButtonState(role: .cancel) { TextState("Cancel") }
        } message: {
            TextState("Selected: \(count). Skipped: \(skipped). Your CSV file will not be changed.")
        }
    }
}
