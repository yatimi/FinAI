//
//  GoalsFeatureTests.swift
//  FinAITests
//
//  Created by Tommy on 08.10.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct GoalsFeatureTests {
    @Test func invalidDraftNeverSavesAndFailedSavePreservesDraftForRetry() async throws {
        var state = GoalsFeature.State()
        state.locale = Locale(identifier: "en_US")
        state.draft = GoalDraft(deadline: TestFixtures.date)
        state.initialDraft = state.draft
        let store = TestStore(initialState: state) { GoalsFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.uuid = .constant(UUID(0))
            $0.goalsClient.save = { _, _ in throw ValidationError.invalidSnapshot }
        }
        var draft = try #require(state.draft)
        draft.name = "MacBook"
        await store.send(.binding(.set(\.draft, draft))) { $0.draft = draft }
        await store.send(.saveTapped) { $0.failure = .invalid }
        draft.target = "2500"
        await store.send(.binding(.set(\.draft, draft))) { $0.draft = draft }
        await store.send(.saveTapped) { $0.phase = .saving; $0.failure = nil }
        await store.receive(.saved(.failure(.saving))) { $0.phase = .idle; $0.failure = .saving }
        #expect(store.state.draft == draft)
        let goal = try draft.goal(id: UUID(0), locale: state.locale)
        store.dependencies.goalsClient.save = { value, expected in
            #expect(value == goal)
            #expect(expected == nil)
            return [value]
        }
        await store.send(.saveTapped) { $0.phase = .saving; $0.failure = nil }
        let plan = try GoalPlanningService().plan(for: goal, on: TestFixtures.date, calendar: TestFixtures.calendar)
        await store.receive(.saved(.success([goal]))) {
            $0.phase = .idle; $0.goals = [goal]; $0.plans = [goal.id: plan]
            $0.draft = nil; $0.initialDraft = nil
        }
    }

    @Test func loadingFailureRequiresRetryBeforeCreatingGoal() async {
        let store = TestStore(initialState: GoalsFeature.State()) { GoalsFeature() } withDependencies: {
            $0.goalsClient.load = { throw ValidationError.invalidSnapshot }
        }
        await store.send(.task) { $0.phase = .loading }
        await store.receive(.loaded(.failure(.loading))) { $0.phase = .idle; $0.failure = .loading }
        await store.send(.addTapped)
        store.dependencies.goalsClient.load = { [] }
        await store.send(.task) { $0.phase = .loading; $0.failure = nil }
        await store.receive(.loaded(.success([]))) { $0.phase = .idle }
    }

    @Test func savingBlocksOverlappingSaveAndDismissal() async {
        var state = GoalsFeature.State()
        state.phase = .saving
        let store = TestStore(initialState: state) { GoalsFeature() }
        await store.send(.saveTapped)
        await store.send(.cancelEditor)
        await store.send(.closeTapped)
        await store.send(.addTapped)
    }

    @Test func cancelledLoadingDoesNotReportFailure() async {
        let store = TestStore(initialState: GoalsFeature.State()) { GoalsFeature() } withDependencies: {
            $0.goalsClient.load = { throw CancellationError() }
        }
        await store.send(.task) { $0.phase = .loading }
        await store.receive(.cancelled) { $0.phase = .idle }
    }

    @Test func editingSendsExpectedGoalAndRetainsDraftOnConflict() async throws {
        let goal = try SavingsGoal(id: UUID(), name: "MacBook", target: Money(amount: 2500, currency: .eur),
                                   saved: Money(amount: 500, currency: .eur), deadline: TestFixtures.date)
        var initial = GoalsFeature.State()
        initial.goals = [goal]
        initial.locale = Locale(identifier: "en_US")
        let store = TestStore(initialState: initial) { GoalsFeature() } withDependencies: {
            $0.date.now = TestFixtures.date
            $0.calendar = TestFixtures.calendar
            $0.goalsClient.save = { edited, expected in
                #expect(expected == goal)
                #expect(edited.id == goal.id)
                #expect(edited.saved.amount == 800)
                throw SavingsGoal.GoalError.changed
            }
        }
        await store.send(.editTapped(goal.id)) {
            $0.expected = goal
            $0.draft = GoalDraft(goal: goal, locale: initial.locale)
            $0.initialDraft = $0.draft
        }
        var draft = try #require(store.state.draft)
        draft.saved = "800"
        await store.send(.binding(.set(\.draft, draft))) { $0.draft = draft }
        await store.send(.saveTapped) { $0.phase = .saving }
        await store.receive(.saved(.failure(.changed))) { $0.phase = .idle; $0.failure = .changed }
        #expect(store.state.draft == draft)
        #expect(store.state.goals == [goal])
    }
}
