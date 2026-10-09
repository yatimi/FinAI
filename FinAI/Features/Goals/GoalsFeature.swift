//
//  GoalsFeature.swift
//  FinAI
//
//  Created by Tommy on 08.10.26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct GoalsFeature {
    enum Phase: Equatable { case idle, loading, saving }
    enum Failure: Error, Equatable { case loading, saving, invalid, changed }
    private enum CancelID { case work }

    @ObservableState
    struct State: Equatable {
        var goals: [SavingsGoal] = []
        var plans: [UUID: GoalPlan] = [:]
        var phase = Phase.idle
        var failure: Failure?
        var draft: GoalDraft?
        var initialDraft: GoalDraft?
        var expected: SavingsGoal?
        var locale = Locale.current
        @Presents var alert: AlertState<Action.Alert>?
        var hasChanges: Bool { draft != initialDraft }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case task
        case loaded(Result<[SavingsGoal], Failure>)
        case saved(Result<[SavingsGoal], Failure>)
        case cancelled
        case addTapped
        case editTapped(UUID)
        case saveTapped
        case cancelEditor
        case closeTapped
        case alert(PresentationAction<Alert>)
        enum Alert: Equatable { case discard, discardAndClose }
    }

    @Dependency(\.goalsClient) var client
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar
    @Dependency(\.uuid) var uuid
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .task:
                guard state.phase == .idle, state.draft == nil else { return .none }
                state.phase = .loading
                state.failure = nil
                let client = client
                return .run { send in
                    do {
                        let goals = try await client.load()
                        try Task.checkCancellation()
                        await send(.loaded(.success(goals)))
                    } catch is CancellationError {
                        await send(.cancelled)
                    } catch { await send(.loaded(.failure(.loading))) }
                }.cancellable(id: CancelID.work)
            case let .loaded(.success(goals)), let .saved(.success(goals)):
                state.phase = .idle
                do {
                    state.plans = try Dictionary(uniqueKeysWithValues: goals.map {
                        ($0.id, try GoalPlanningService().plan(for: $0, on: now, calendar: calendar))
                    })
                    state.goals = goals
                    state.failure = nil
                    if case .saved = action { clearEditor(&state) }
                } catch { state.failure = .loading }
                return .none
            case let .loaded(.failure(failure)), let .saved(.failure(failure)):
                state.phase = .idle
                state.failure = failure
                return .none
            case .addTapped:
                guard state.phase == .idle, state.failure != .loading, state.draft == nil else { return .none }
                let deadline = calendar.date(byAdding: .month, value: 3, to: now) ?? now
                state.draft = GoalDraft(deadline: deadline)
                state.initialDraft = state.draft
                state.expected = nil
                state.failure = nil
                return .none
            case let .editTapped(id):
                guard state.phase == .idle, state.draft == nil,
                      let goal = state.goals.first(where: { $0.id == id }) else { return .none }
                state.expected = goal
                state.draft = GoalDraft(goal: goal, locale: state.locale)
                state.initialDraft = state.draft
                state.failure = nil
                return .none
            case .saveTapped:
                guard state.phase == .idle, state.hasChanges, let draft = state.draft else { return .none }
                let goal: SavingsGoal
                do {
                    goal = try draft.goal(id: state.expected?.id ?? uuid(), locale: state.locale)
                    _ = try GoalPlanningService().plan(for: goal, on: now, calendar: calendar)
                } catch { state.failure = .invalid; return .none }
                state.phase = .saving
                state.failure = nil
                let client = client
                let expected = state.expected
                return .run { send in
                    do { await send(.saved(.success(try await client.save(goal, expected)))) }
                    catch is CancellationError { await send(.cancelled) }
                    catch { await send(.saved(.failure(error as? SavingsGoal.GoalError == .changed ? .changed : .saving))) }
                }.cancellable(id: CancelID.work)
            case .cancelEditor, .closeTapped:
                guard state.phase != .saving else { return .none }
                let closing = action == .closeTapped
                if state.hasChanges {
                    state.alert = AlertState {
                        TextState(.discardGoalChanges)
                    } actions: {
                        ButtonState(role: .destructive, action: closing ? .discardAndClose : .discard) { TextState(.discardChanges) }
                        ButtonState(role: .cancel) { TextState(.cancel) }
                    }
                    return .none
                }
                clearEditor(&state)
                return closing ? .merge(.cancel(id: CancelID.work), .run { _ in await dismiss() }) : .none
            case .cancelled:
                state.phase = .idle
                return .none
            case .alert(.presented(.discard)):
                clearEditor(&state)
                return .none
            case .alert(.presented(.discardAndClose)):
                clearEditor(&state)
                return .merge(.cancel(id: CancelID.work), .run { _ in await dismiss() })
            case .binding, .alert:
                return .none
            }
        }.ifLet(\.$alert, action: \.alert)
    }

    private func clearEditor(_ state: inout State) {
        state.draft = nil
        state.initialDraft = nil
        state.expected = nil
        state.failure = nil
    }
}
