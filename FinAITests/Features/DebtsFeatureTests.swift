//
//  DebtsFeatureTests.swift
//  FinAITests
//
//  Created by Tommy on 25.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct DebtsFeatureTests {
    @Test func invalidDraftNeverSavesThenRetryPreservesDraft() async throws {
        var state = DebtsFeature.State()
        state.locale = Locale(identifier: "en_US")
        state.draft = DebtDraft(date: TestFixtures.date)
        state.initialDraft = state.draft
        let store = TestStore(initialState: state) { DebtsFeature() } withDependencies: {
            $0.date.now = TestFixtures.date; $0.calendar = TestFixtures.calendar; $0.uuid = .constant(UUID(0))
            $0.debtsClient.save = { _, _, _, _ in throw ValidationError.invalidSnapshot }
        }
        var draft = try #require(state.draft)
        draft.person = "Alex"
        await store.send(.binding(.set(\.draft, draft))) { $0.draft = draft }
        await store.send(.saveTapped) { $0.failure = .invalid }
        draft.amount = "100"
        await store.send(.binding(.set(\.draft, draft))) { $0.draft = draft; $0.failure = nil }
        await store.send(.saveTapped) { $0.phase = .saving }
        await store.receive(.saved(.failure(.saving))) { $0.phase = .idle; $0.failure = .saving }
        #expect(store.state.draft == draft)
        let debt = try draft.debt(id: UUID(0), locale: state.locale)
        store.dependencies.debtsClient.save = { value, expected, _, _ in
            #expect(value == debt); #expect(expected == nil); return [value]
        }
        await store.send(.saveTapped) { $0.phase = .saving; $0.failure = nil }
        let progress = try DebtPlanningService().progress(for: debt, on: TestFixtures.date, calendar: TestFixtures.calendar)
        await store.receive(.saved(.success([debt]))) {
            $0.phase = .idle; $0.debts = [debt]; $0.progress = [debt.id: progress]
            $0.draft = nil; $0.initialDraft = nil
        }
    }

    @Test func repaymentConflictKeepsHistoryAndDraft() async throws {
        let debt = try PersonalDebt(id: UUID(), person: "Alex", direction: .iOwe, principal: Money(amount: 100, currency: .eur), date: TestFixtures.date, dueDate: nil)
        var state = DebtsFeature.State()
        state.debts = [debt]
        state.progress[debt.id] = try DebtPlanningService().progress(for: debt, on: TestFixtures.date, calendar: TestFixtures.calendar)
        let store = TestStore(initialState: state) { DebtsFeature() } withDependencies: {
            $0.date.now = TestFixtures.date; $0.calendar = TestFixtures.calendar; $0.uuid = .constant(UUID(1))
            $0.debtsClient.save = { updated, expected, _, _ in
                #expect(expected == debt); #expect(updated.repayments.count == 1)
                #expect(updated.repayments.first?.amount.amount == 20)
                throw PersonalDebt.DebtError.changed
            }
        }
        await store.send(.repayTapped(debt.id)) {
            $0.expected = debt; $0.repayment = RepaymentDraft(date: TestFixtures.date); $0.initialRepayment = $0.repayment
        }
        var draft = try #require(store.state.repayment)
        draft.amount = "101"
        await store.send(.binding(.set(\.repayment, draft))) { $0.repayment = draft }
        await store.send(.saveTapped) { $0.failure = .invalid }
        draft.amount = "20"
        await store.send(.binding(.set(\.repayment, draft))) { $0.repayment = draft; $0.failure = nil }
        await store.send(.saveTapped) { $0.phase = .saving }
        await store.receive(.saved(.failure(.changed))) { $0.phase = .idle; $0.failure = .changed }
        #expect(store.state.debts == [debt])
        #expect(store.state.repayment == draft)
    }

    @Test func failureRequiresReloadAndCancellationIsNotAnError() async {
        let store = TestStore(initialState: DebtsFeature.State()) { DebtsFeature() } withDependencies: {
            $0.date.now = TestFixtures.date; $0.calendar = TestFixtures.calendar
            $0.debtsClient.load = { _, _ in throw ValidationError.invalidSnapshot }
        }
        await store.send(.task) { $0.phase = .loading }
        await store.receive(.loaded(.failure(.loading))) { $0.phase = .idle; $0.failure = .loading }
        await store.send(.addTapped)
        store.dependencies.debtsClient.load = { _, _ in throw CancellationError() }
        await store.send(.task) { $0.phase = .loading; $0.failure = nil }
        await store.receive(.cancelled) { $0.phase = .idle }
        store.dependencies.debtsClient.load = { _, _ in [] }
        await store.send(.task) { $0.phase = .loading }
        await store.receive(.loaded(.success([]))) { $0.phase = .idle }
    }

    @Test func savingBlocksOverlappingSaveAndDismissal() async {
        var state = DebtsFeature.State()
        state.phase = .saving
        let store = TestStore(initialState: state) { DebtsFeature() }
        await store.send(.saveTapped)
        await store.send(.closeTapped)
        await store.send(.cancelEditor)
        await store.send(.addTapped)
    }

    @Test func planAddEntryWaitsForSuccessfulLoad() async {
        let store = TestStore(initialState: AppFeature.State()) { AppFeature() } withDependencies: {
            $0.date.now = TestFixtures.date; $0.calendar = TestFixtures.calendar
            $0.debtsClient.load = { _, _ in [] }
        }
        await store.send(.addDebtTapped) { $0.debts = DebtsFeature.State(addAfterLoading: true) }
        await store.send(.debts(.presented(.task))) { $0.debts?.phase = .loading }
        await store.receive(.debts(.presented(.loaded(.success([]))))) {
            $0.debts?.phase = .idle; $0.debts?.addAfterLoading = false
        }
        await store.receive(.debts(.presented(.addTapped))) {
            $0.debts?.draft = DebtDraft(date: TestFixtures.date)
            $0.debts?.initialDraft = DebtDraft(date: TestFixtures.date)
        }
    }

    @Test func dirtyDraftRequiresExplicitDiscard() async throws {
        var state = DebtsFeature.State()
        state.initialDraft = DebtDraft(date: TestFixtures.date)
        state.draft = state.initialDraft
        state.draft?.person = "Alex"
        let store = TestStore(initialState: state) { DebtsFeature() }
        await store.send(.cancelEditor) {
            $0.alert = AlertState {
                TextState(.discardDebtChanges)
            } actions: {
                ButtonState(role: .destructive, action: .discard) { TextState(.discardChanges) }
                ButtonState(role: .cancel) { TextState(.cancel) }
            }
        }
        await store.send(.alert(.presented(.discard))) { $0.alert = nil; $0.draft = nil; $0.initialDraft = nil }
    }
}
