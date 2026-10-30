//
//  DebtsFeature.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct DebtsFeature {
    enum Phase: Equatable { case idle, loading, saving }
    enum Failure: Error, Equatable { case loading, saving, invalid, changed }
    private enum CancelID { case work }

    @ObservableState
    struct State: Equatable {
        var addAfterLoading = false
        var debts: [PersonalDebt] = []
        var progress: [UUID: DebtProgress] = [:]
        var phase = Phase.idle
        var failure: Failure?
        var draft: DebtDraft?
        var initialDraft: DebtDraft?
        var repayment: RepaymentDraft?
        var initialRepayment: RepaymentDraft?
        var expected: PersonalDebt?
        var locale = Locale.current
        @Presents var alert: AlertState<Action.Alert>?
        var hasChanges: Bool { draft != initialDraft || repayment != initialRepayment }
        var isEditing: Bool { draft != nil || repayment != nil }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case task
        case loaded(Result<[PersonalDebt], Failure>)
        case saved(Result<[PersonalDebt], Failure>)
        case cancelled
        case addTapped
        case repayTapped(UUID)
        case saveTapped
        case cancelEditor
        case closeTapped
        case alert(PresentationAction<Alert>)
        enum Alert: Equatable { case discard, discardAndClose }
    }

    @Dependency(\.debtsClient) var client
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar
    @Dependency(\.uuid) var uuid
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .task:
                guard state.phase == .idle, !state.isEditing else { return .none }
                state.phase = .loading
                state.failure = nil
                let client = client, date = now, calendar = calendar
                return .run { send in
                    do {
                        let debts = try await client.load(date, calendar)
                        try Task.checkCancellation()
                        await send(.loaded(.success(debts)))
                    } catch is CancellationError { await send(.cancelled) }
                    catch { await send(.loaded(.failure(.loading))) }
                }.cancellable(id: CancelID.work)
            case let .loaded(.success(debts)), let .saved(.success(debts)):
                state.phase = .idle
                do {
                    var progress: [UUID: DebtProgress] = [:]
                    for debt in debts {
                        guard progress[debt.id] == nil else { throw PersonalDebt.DebtError.invalid }
                        progress[debt.id] = try DebtPlanningService().progress(for: debt, on: now, calendar: calendar)
                    }
                    state.debts = debts
                    state.progress = progress
                    state.failure = nil
                    if case .saved = action { clearEditor(&state) }
                    if state.addAfterLoading {
                        state.addAfterLoading = false
                        return .send(.addTapped)
                    }
                } catch { state.failure = .loading }
                return .none
            case let .loaded(.failure(failure)), let .saved(.failure(failure)):
                state.phase = .idle
                state.failure = failure
                return .none
            case .addTapped:
                guard state.phase == .idle, state.failure != .loading, !state.isEditing else { return .none }
                state.draft = DebtDraft(date: now)
                state.initialDraft = state.draft
                state.failure = nil
                return .none
            case let .repayTapped(id):
                guard state.phase == .idle, !state.isEditing,
                      let debt = state.debts.first(where: { $0.id == id }),
                      state.progress[id]?.status != .settled else { return .none }
                state.expected = debt
                state.repayment = RepaymentDraft(date: now)
                state.initialRepayment = state.repayment
                state.failure = nil
                return .none
            case .saveTapped:
                guard state.phase == .idle, state.hasChanges else { return .none }
                let debt: PersonalDebt
                do {
                    if let draft = state.draft {
                        debt = try draft.debt(id: uuid(), locale: state.locale)
                    } else if let draft = state.repayment, let expected = state.expected {
                        debt = try DebtPlanningService().adding(
                            draft.repayment(id: uuid(), currency: expected.principal.currency, locale: state.locale),
                            to: expected, on: now, calendar: calendar)
                    } else { return .none }
                    _ = try DebtPlanningService().progress(for: debt, on: now, calendar: calendar)
                } catch { state.failure = .invalid; return .none }
                state.phase = .saving
                state.failure = nil
                let client = client, expected = state.expected, date = now, calendar = calendar
                return .run { send in
                    do { await send(.saved(.success(try await client.save(debt, expected, date, calendar)))) }
                    catch is CancellationError { await send(.cancelled) }
                    catch { await send(.saved(.failure(error as? PersonalDebt.DebtError == .changed ? .changed : .saving))) }
                }.cancellable(id: CancelID.work)
            case .cancelEditor, .closeTapped:
                guard state.phase != .saving else { return .none }
                let closing = action == .closeTapped
                if state.hasChanges {
                    state.alert = AlertState {
                        TextState(.discardDebtChanges)
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
            case .binding:
                if state.hasChanges, state.failure == .invalid { state.failure = nil }
                return .none
            case .alert:
                return .none
            }
        }.ifLet(\.$alert, action: \.alert)
    }

    private func clearEditor(_ state: inout State) {
        state.draft = nil; state.initialDraft = nil
        state.repayment = nil; state.initialRepayment = nil
        state.expected = nil; state.failure = nil
    }
}
