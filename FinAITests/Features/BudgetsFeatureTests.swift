//
//  BudgetsFeatureTests.swift
//  FinAITests
//
//  Created by Tommy on 09.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct BudgetsFeatureTests {
    @Test func invalidDraftNeverSavesAndFailedSavePreservesDraftForRetry() async throws {
        var state = BudgetsFeature.State()
        state.locale = Locale(identifier: "en_US")
        state.draft = BudgetDraft()
        state.initialDraft = state.draft
        let store = TestStore(initialState: state) { BudgetsFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.uuid = .constant(UUID(0))
            $0.budgetsClient.save = { _, _ in throw ValidationError.invalidSnapshot }
        }
        var draft = try #require(state.draft)
        draft.limit = "abc"
        await store.send(.binding(.set(\.draft, draft))) { $0.draft = draft }
        await store.send(.saveTapped) { $0.failure = .invalid }
        draft.limit = "2500"
        await store.send(.binding(.set(\.draft, draft))) { $0.draft = draft }
        await store.send(.saveTapped) { $0.phase = .saving; $0.failure = nil }
        await store.receive(.saved(.failure(.saving))) { $0.phase = .idle; $0.failure = .saving }
        #expect(store.state.draft == draft)
        let budget = try draft.budget(id: UUID(0), locale: state.locale)
        store.dependencies.budgetsClient.save = { value, expected in
            #expect(value == budget)
            #expect(expected == nil)
            return [value]
        }
        await store.send(.saveTapped) { $0.phase = .saving; $0.failure = nil }
        let plan = try BudgetPlanningService().progress(for: budget, transactions: [], on: TestFixtures.date, calendar: TestFixtures.calendar)
        await store.receive(.saved(.success([budget]))) {
            $0.phase = .idle; $0.budgets = [budget]; $0.plans = [budget.id: plan]
            $0.draft = nil; $0.initialDraft = nil
        }
    }

    @Test func loadingFailureRequiresRetryBeforeCreatingBudget() async {
        let store = TestStore(initialState: BudgetsFeature.State()) { BudgetsFeature() } withDependencies: {
            $0.budgetsClient.load = { throw ValidationError.invalidSnapshot }
        }
        await store.send(.task) { $0.phase = .loading }
        await store.receive(.loaded(.failure(.loading))) { $0.phase = .idle; $0.failure = .loading }
        await store.send(.addTapped)
        store.dependencies.budgetsClient.load = { [] }
        await store.send(.task) { $0.phase = .loading; $0.failure = nil }
        await store.receive(.loaded(.success([]))) { $0.phase = .idle }
    }

    @Test func savingBlocksOverlappingSaveAndDismissal() async {
        var state = BudgetsFeature.State()
        state.phase = .saving
        let store = TestStore(initialState: state) { BudgetsFeature() }
        await store.send(.saveTapped)
        await store.send(.cancelEditor)
        await store.send(.closeTapped)
        await store.send(.addTapped)
    }

    @Test func cancelledLoadingDoesNotReportFailure() async {
        let store = TestStore(initialState: BudgetsFeature.State()) { BudgetsFeature() } withDependencies: {
            $0.budgetsClient.load = { throw CancellationError() }
        }
        await store.send(.task) { $0.phase = .loading }
        await store.receive(.cancelled) { $0.phase = .idle }
    }

    @Test func editingSendsExpectedBudgetAndRetainsDraftOnConflict() async throws {
        let budget = try CategoryBudget(id: UUID(), category: .groceries, limit: Money(amount: 500, currency: .eur))
        var initial = BudgetsFeature.State()
        initial.budgets = [budget]
        initial.locale = Locale(identifier: "en_US")
        let store = TestStore(initialState: initial) { BudgetsFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.budgetsClient.save = { edited, expected in
                #expect(expected == budget)
                #expect(edited.id == budget.id)
                #expect(edited.limit.amount == 800)
                throw CategoryBudget.BudgetError.changed
            }
        }
        await store.send(.editTapped(budget.id)) {
            $0.expected = budget
            $0.draft = BudgetDraft(budget: budget, locale: initial.locale)
            $0.initialDraft = $0.draft
        }
        var draft = try #require(store.state.draft)
        draft.limit = "800"
        await store.send(.binding(.set(\.draft, draft))) { $0.draft = draft }
        await store.send(.saveTapped) { $0.phase = .saving }
        await store.receive(.saved(.failure(.changed))) { $0.phase = .idle; $0.failure = .changed }
        #expect(store.state.draft == draft)
        #expect(store.state.budgets == [budget])
    }
    @Test func duplicateSavePreservesDraftAndDiscardRequiresConfirmation() async throws {
        var initial = BudgetsFeature.State()
        initial.locale = Locale(identifier: "en_US")
        initial.draft = BudgetDraft()
        initial.initialDraft = initial.draft
        initial.draft?.limit = "100"
        let store = TestStore(initialState: initial) { BudgetsFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.uuid = .constant(UUID(0))
            $0.budgetsClient.save = { _, _ in throw CategoryBudget.BudgetError.duplicate }
        }
        await store.send(.saveTapped) { $0.phase = .saving }
        await store.receive(.saved(.failure(.duplicate))) { $0.phase = .idle; $0.failure = .duplicate }
        #expect(store.state.draft == initial.draft)
        await store.send(.cancelEditor) {
            $0.alert = AlertState {
                TextState(.discardBudgetChanges)
            } actions: {
                ButtonState(role: .destructive, action: .discard) { TextState(.discardChanges) }
                ButtonState(role: .cancel) { TextState(.cancel) }
            }
        }
        await store.send(.alert(.presented(.discard))) {
            $0.alert = nil; $0.draft = nil; $0.initialDraft = nil; $0.failure = nil
        }
    }

    @Test func refreshedTransactionsUpdateProgressWithoutDiscardingDraft() async throws {
        let budget = try CategoryBudget(id: UUID(), category: .other, limit: Money(amount: 100, currency: .eur))
        var initial = BudgetsFeature.State()
        initial.budgets = [budget]
        initial.draft = BudgetDraft()
        initial.initialDraft = initial.draft
        initial.draft?.limit = "200"
        let rows = try [TestFixtures.transaction(amount: 125)]
        let progress = try BudgetPlanningService().progress(for: budget, transactions: rows, on: TestFixtures.date, calendar: TestFixtures.calendar)
        let store = TestStore(initialState: initial) { BudgetsFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
        }
        await store.send(.transactionsUpdated(rows)) {
            $0.transactions = rows; $0.plans = [budget.id: progress]
        }
        #expect(store.state.draft == initial.draft)
        #expect(store.state.plans[budget.id]?.exceeded.amount == 25)
    }

}
