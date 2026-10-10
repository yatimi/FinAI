//
//  BudgetsFeature.swift
//  FinAI
//
//  Created by Tommy on 09.10.26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct BudgetsFeature {
    enum Phase: Equatable { case idle, loading, saving }
    enum Failure: Error, Equatable { case loading, saving, invalid, changed, duplicate }
    private enum CancelID { case work }

    @ObservableState
    struct State: Equatable {
        var budgets: [CategoryBudget] = []
        var transactions: [Transaction] = []
        var plans: [UUID: BudgetProgress] = [:]
        var phase = Phase.idle
        var failure: Failure?
        var draft: BudgetDraft?
        var initialDraft: BudgetDraft?
        var expected: CategoryBudget?
        var locale = Locale.current
        @Presents var alert: AlertState<Action.Alert>?
        var hasChanges: Bool { draft != initialDraft }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case task
        case transactionsUpdated([Transaction])
        case loaded(Result<[CategoryBudget], Failure>)
        case saved(Result<[CategoryBudget], Failure>)
        case cancelled
        case addTapped
        case editTapped(UUID)
        case saveTapped
        case cancelEditor
        case closeTapped
        case alert(PresentationAction<Alert>)
        enum Alert: Equatable { case discard, discardAndClose }
    }

    @Dependency(\.budgetsClient) var client
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar
    @Dependency(\.uuid) var uuid
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case let .transactionsUpdated(transactions):
                state.transactions = transactions
                do {
                    state.plans = try Dictionary(uniqueKeysWithValues: state.budgets.map {
                        ($0.id, try BudgetPlanningService().progress(for: $0, transactions: transactions, on: now, calendar: calendar))
                    })
                } catch { state.failure = .loading }
                return .none
            case .task:
                guard state.phase == .idle, state.draft == nil else { return .none }
                state.phase = .loading
                state.failure = nil
                let client = client
                return .run { send in
                    do {
                        let budgets = try await client.load()
                        try Task.checkCancellation()
                        await send(.loaded(.success(budgets)))
                    } catch is CancellationError {
                        await send(.cancelled)
                    } catch { await send(.loaded(.failure(.loading))) }
                }.cancellable(id: CancelID.work)
            case let .loaded(.success(budgets)), let .saved(.success(budgets)):
                state.phase = .idle
                do {
                    state.plans = try Dictionary(uniqueKeysWithValues: budgets.map {
                        ($0.id, try BudgetPlanningService().progress(for: $0, transactions: state.transactions, on: now, calendar: calendar))
                    })
                    state.budgets = budgets
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
                state.draft = BudgetDraft()
                state.initialDraft = state.draft
                state.expected = nil
                state.failure = nil
                return .none
            case let .editTapped(id):
                guard state.phase == .idle, state.draft == nil,
                      let budget = state.budgets.first(where: { $0.id == id }) else { return .none }
                state.expected = budget
                state.draft = BudgetDraft(budget: budget, locale: state.locale)
                state.initialDraft = state.draft
                state.failure = nil
                return .none
            case .saveTapped:
                guard state.phase == .idle, state.hasChanges, let draft = state.draft else { return .none }
                let budget: CategoryBudget
                do {
                    budget = try draft.budget(id: state.expected?.id ?? uuid(), locale: state.locale)
                    _ = try BudgetPlanningService().progress(for: budget, transactions: state.transactions, on: now, calendar: calendar)
                } catch { state.failure = .invalid; return .none }
                state.phase = .saving
                state.failure = nil
                let client = client
                let expected = state.expected
                return .run { send in
                    do { await send(.saved(.success(try await client.save(budget, expected)))) }
                    catch is CancellationError { await send(.cancelled) }
                    catch {
                        let failure: Failure
                        switch error as? CategoryBudget.BudgetError {
                        case .changed: failure = .changed
                        case .duplicate: failure = .duplicate
                        default: failure = .saving
                        }
                        await send(.saved(.failure(failure)))
                    }
                }.cancellable(id: CancelID.work)
            case .cancelEditor, .closeTapped:
                guard state.phase != .saving else { return .none }
                let closing = action == .closeTapped
                if state.hasChanges {
                    state.alert = AlertState {
                        TextState(.discardBudgetChanges)
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
