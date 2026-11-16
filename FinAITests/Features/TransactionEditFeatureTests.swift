//
//  TransactionEditFeatureTests.swift
//  FinAITests
//
//  Created by Tommy on 07.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct TransactionEditFeatureTests {
    @Test func invalidInputKeepsDraftAndNeverStartsSaving() async throws {
        let transaction = try TestFixtures.transaction(amount: 10, accountID: ImportFixtures.account.id)
        let store = TestStore(initialState: TransactionEditFeature.State(transaction: transaction, accounts: [ImportFixtures.account], locale: Locale(identifier: "en_US"))) { TransactionEditFeature() }
        await store.send(.binding(.set(\.draft.amount, "bad"))) { $0.draft.amount = "bad" }
        await store.send(.saveTapped) { $0.failure = .invalidAmount }
        // Resigning keyboard focus may send the same value again; keep the error until a real correction.
        await store.send(.binding(.set(\.draft.amount, "bad")))
        await store.send(.binding(.set(\.draft.amount, "20"))) {
            $0.draft.amount = "20"
            $0.failure = nil
        }
        #expect(store.state.hasChanges)
    }

    @Test func failurePreservesDraftAndRetryDeliversUpdatedOverview() async throws {
        let transaction = try TestFixtures.transaction(amount: 10, accountID: ImportFixtures.account.id)
        let initial = TransactionEditFeature.State(transaction: transaction, accounts: [ImportFixtures.account], locale: Locale(identifier: "en_US"))
        let store = TestStore(initialState: initial) { TransactionEditFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.financeClient.editTransaction = { _, _, _, _ in throw TransactionEditError.saving }
        }
        await store.send(.saveTapped)
        await store.send(.binding(.set(\.draft.merchant, "Edited"))) { $0.draft.merchant = "Edited" }
        await store.send(.saveTapped) { $0.isSaving = true }
        await store.receive(.saved(.failure(.saving))) {
            $0.isSaving = false
            $0.failure = .saving
        }
        let replacement = try store.state.draft.transaction(replacing: transaction, locale: initial.locale)
        let snapshot = try TransactionEditService().replacing(transaction, with: replacement, in: FinanceSnapshot(accounts: [ImportFixtures.account], transactions: [transaction]))
        let overview = try FinanceOverview.make(snapshot: snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        store.dependencies.financeClient.editTransaction = { expected, edited, _, _ in
            #expect(expected == transaction)
            #expect(edited == replacement)
            return overview
        }
        await store.send(.saveTapped) {
            $0.isSaving = true
            $0.failure = nil
        }
        await store.receive(.saved(.success(overview))) { $0.isSaving = false }
        await store.receive(.delegate(.didSave(overview)))
    }

    @Test func savingPreventsDuplicateSaveAndCancellation() async throws {
        let transaction = try TestFixtures.transaction(amount: 10, accountID: ImportFixtures.account.id)
        let clock = TestClock()
        let store = TestStore(initialState: TransactionEditFeature.State(transaction: transaction, accounts: [ImportFixtures.account], locale: Locale(identifier: "en_US"))) { TransactionEditFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.financeClient.editTransaction = { _, _, _, _ in
                try await clock.sleep(for: .seconds(1))
                throw CancellationError()
            }
        }
        await store.send(.binding(.set(\.draft.merchant, "Edited"))) { $0.draft.merchant = "Edited" }
        await store.send(.saveTapped) { $0.isSaving = true }
        await store.send(.saveTapped)
        await store.send(.cancelTapped)
        await clock.advance(by: .seconds(1))
        await store.receive(.saveCancelled) { $0.isSaving = false }
        #expect(store.state.failure == nil)
        #expect(store.state.draft.merchant == "Edited")
    }

    @Test func cancelWithChangesRequiresDiscardConfirmation() async throws {
        let transaction = try TestFixtures.transaction(amount: 10, accountID: ImportFixtures.account.id)
        let store = TestStore(initialState: TransactionEditFeature.State(transaction: transaction, accounts: [ImportFixtures.account], locale: Locale(identifier: "en_US"))) { TransactionEditFeature() }
        await store.send(.binding(.set(\.draft.merchant, "Edited"))) { $0.draft.merchant = "Edited" }
        await store.send(.cancelTapped) {
            $0.alert = AlertState {
                TextState(.discardTransactionChanges)
            } actions: {
                ButtonState(role: .destructive, action: .discard) { TextState(.discardChanges) }
                ButtonState(role: .cancel) { TextState(.keepEditing) }
            } message: { TextState(.transactionChangesNotSaved) }
        }
        await store.send(.alert(.dismiss)) { $0.alert = nil }
        #expect(store.state.hasChanges)
    }

    @Test func listEditOpensScopedEditorAndSavingUpdatesDetailAndRoot() async throws {
        let locale = Locale(identifier: "en_US")
        let transaction = try TestFixtures.transaction(amount: 10, accountID: ImportFixtures.account.id)
        let snapshot = FinanceSnapshot(accounts: [ImportFixtures.account], transactions: [transaction])
        var draft = TransactionEditDraft(transaction: transaction, locale: locale)
        draft.merchant = "Edited"
        let replacement = try draft.transaction(replacing: transaction, locale: locale)
        let overview = try FinanceOverview.make(snapshot: TransactionEditService().replacing(transaction, with: replacement, in: snapshot), date: TestFixtures.date, calendar: TestFixtures.calendar)
        var state = AppFeature.State()
        state.overview = try FinanceOverview.make(snapshot: snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.locale = locale
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.financeClient.editTransaction = { _, _, _, _ in overview }
        }
        await store.send(.transactions(.editTapped(transaction.id))) {
            $0.detail = TransactionDetailFeature.State(transaction: transaction, accountName: ImportFixtures.account.name, accounts: snapshot.accounts)
        }
        await store.receive(.detail(.presented(.editTapped))) {
            $0.detail?.editor = TransactionEditFeature.State(transaction: transaction, accounts: snapshot.accounts, locale: locale)
        }
        await store.send(.detail(.presented(.editor(.presented(.binding(.set(\.draft.merchant, "Edited"))))))) {
            $0.detail?.editor?.draft.merchant = "Edited"
        }
        await store.send(.detail(.presented(.editor(.presented(.saveTapped))))) { $0.detail?.editor?.isSaving = true }
        await store.receive(.detail(.presented(.editor(.presented(.saved(.success(overview))))))) { $0.detail?.editor?.isSaving = false }
        await store.receive(.detail(.presented(.editor(.presented(.delegate(.didSave(overview))))))) {
            $0.detail?.editor = nil
            $0.detail?.transaction = replacement
            $0.detail?.original = transaction
        }
        await store.receive(.detail(.presented(.delegate(.didUpdate(overview))))) {
            $0.overview = overview
            $0.transactions.update(snapshot: overview.snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        }
    }

    @Test func savedCorrectionUpdatesRootAndFiltersWithoutASecondLoad() async throws {
        let transaction = try TestFixtures.transaction(amount: 10, accountID: ImportFixtures.account.id)
        var draft = TransactionEditDraft(transaction: transaction, locale: Locale(identifier: "en_US"))
        draft.merchant = "Different merchant"
        let edited = try draft.transaction(replacing: transaction, locale: Locale(identifier: "en_US"))
        let before = FinanceSnapshot(accounts: [ImportFixtures.account], transactions: [transaction])
        let overview = try FinanceOverview.make(snapshot: TransactionEditService().replacing(transaction, with: edited, in: before), date: TestFixtures.date, calendar: TestFixtures.calendar)
        var state = AppFeature.State()
        state.overview = try FinanceOverview.make(snapshot: before, date: TestFixtures.date, calendar: TestFixtures.calendar)
        state.transactions.update(snapshot: before, date: TestFixtures.date, calendar: TestFixtures.calendar)
        state.transactions.query.text = transaction.merchant
        state.detail = TransactionDetailFeature.State(transaction: transaction, accountName: ImportFixtures.account.name, accounts: before.accounts)
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
        }
        await store.send(.detail(.presented(.delegate(.didUpdate(overview))))) {
            $0.overview = overview
            $0.transactions.update(snapshot: overview.snapshot, date: TestFixtures.date, calendar: TestFixtures.calendar)
        }
        #expect(store.state.transactions.query.text == transaction.merchant)
        #expect(store.state.transactions.results.isEmpty)
    }
}
