//
//  MerchantRulesFeature.swift
//  FinAI
//
//  Created by Tommy on 02.10.26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct MerchantRulesFeature {
    enum Failure: Error, Equatable { case loading, saving, invalid, conflict, missing }
    enum Phase: Equatable { case idle, loading, saving }
    private enum CancelID { case work }

    @ObservableState
    struct State: Equatable {
        var rules: [MerchantRule] = []
        var phase = Phase.idle
        var failure: Failure?
        var isEditorPresented = false
        var editingID: UUID?
        var pattern = ""
        var matchMode = MerchantRule.MatchMode.exact
        var kind = Transaction.Kind.expense
        var merchant = ""
        var category = Category.other
        @Presents var alert: AlertState<Action.Alert>?

        init(candidate: ImportCandidate? = nil) {
            if let candidate {
                isEditorPresented = true
                pattern = candidate.description
                merchant = candidate.merchant
                kind = candidate.kind
                category = candidate.category
            }
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case task
        case response(Result<[MerchantRule], Failure>)
        case saved(Result<[MerchantRule], Failure>)
        case addTapped
        case editTapped(UUID)
        case cancelEditor
        case saveTapped
        case deleteTapped(UUID)
        case alert(PresentationAction<Alert>)
        case closeTapped
        enum Alert: Equatable { case confirmDelete(UUID) }
    }

    @Dependency(\.merchantRulesClient) var client
    @Dependency(\.uuid) var uuid
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .task:
                guard state.phase == .idle else { return .none }
                state.phase = .loading
                state.failure = nil
                let client = client
                return .run { send in
                    do {
                        let rules = try await client.load()
                        try Task.checkCancellation()
                        await send(.response(.success(rules)))
                    } catch is CancellationError {} catch { await send(.response(.failure(.loading))) }
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case let .response(.success(rules)):
                state.rules = rules
                state.phase = .idle
                return .none
            case let .response(.failure(failure)), let .saved(.failure(failure)):
                state.phase = .idle
                state.failure = failure
                return .none
            case let .saved(.success(rules)):
                state.phase = .idle
                state.rules = rules
                state.isEditorPresented = false
                state.editingID = nil
                state.failure = nil
                return .none
            case .addTapped:
                guard state.phase == .idle, state.failure != .loading else { return .none }
                state.editingID = nil
                state.pattern = ""
                state.merchant = ""
                state.matchMode = .exact
                state.kind = .expense
                state.category = .other
                state.isEditorPresented = true
                state.failure = nil
                return .none
            case let .editTapped(id):
                guard state.phase == .idle, let rule = state.rules.first(where: { $0.id == id }) else { return .none }
                state.editingID = id
                state.pattern = rule.pattern
                state.matchMode = rule.matchMode
                state.kind = rule.kind
                state.merchant = rule.merchant
                state.category = rule.category
                state.isEditorPresented = true
                state.failure = nil
                return .none
            case .cancelEditor:
                guard state.phase == .idle else { return .none }
                state.isEditorPresented = false
                state.failure = nil
                return .none
            case .saveTapped:
                guard state.phase == .idle, state.failure != .loading else { return .none }
                let rule = MerchantRule(
                    id: state.editingID ?? uuid(),
                    pattern: state.pattern.trimmingCharacters(in: .whitespacesAndNewlines),
                    matchMode: state.matchMode, kind: state.kind,
                    merchant: state.merchant.trimmingCharacters(in: .whitespacesAndNewlines), category: state.category
                )
                do { try rule.validate() } catch {
                    state.failure = .invalid
                    return .none
                }
                let replacingExisting = state.editingID != nil
                state.phase = .saving
                state.failure = nil
                let client = client
                return .run { send in
                    do { await send(.saved(.success(try await client.save(rule, replacingExisting)))) }
                    catch is CancellationError {} catch {
                        let failure: Failure
                        switch error as? MerchantRule.RuleError {
                        case .conflict: failure = .conflict
                        case .invalid: failure = .invalid
                        case .missing: failure = .missing
                        case nil: failure = .saving
                        }
                        await send(.saved(.failure(failure)))
                    }
                }.cancellable(id: CancelID.work)
            case let .deleteTapped(id):
                guard state.phase == .idle else { return .none }
                state.alert = AlertState {
                    TextState("Delete merchant rule?")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete(id)) { TextState("Delete rule") }
                    ButtonState(role: .cancel) { TextState("Cancel") }
                } message: { TextState("Saved transactions will stay unchanged.") }
                return .none
            case let .alert(.presented(.confirmDelete(id))):
                guard state.phase == .idle else { return .none }
                state.phase = .saving
                state.failure = nil
                let client = client
                return .run { send in
                    do { await send(.saved(.success(try await client.delete(id)))) }
                    catch is CancellationError {} catch { await send(.saved(.failure(.saving))) }
                }.cancellable(id: CancelID.work)
            case .closeTapped:
                guard state.phase != .saving else { return .none }
                return .merge(.cancel(id: CancelID.work), .run { _ in await dismiss() })
            case .binding:
                if state.failure != .loading { state.failure = nil }
                return .none
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
