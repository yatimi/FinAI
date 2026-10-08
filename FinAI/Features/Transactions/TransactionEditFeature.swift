//
//  TransactionEditFeature.swift
//  FinAI
//
//  Created by Tommy on 07.10.26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TransactionEditFeature {
    @ObservableState
    struct State: Equatable {
        let expected: Transaction
        let accounts: [Account]
        let locale: Locale
        let initialDraft: TransactionEditDraft
        var draft: TransactionEditDraft
        var isSaving = false
        var failure: TransactionEditError?
        @Presents var alert: AlertState<Action.Alert>?

        init(transaction: Transaction, accounts: [Account], locale: Locale) {
            expected = transaction
            self.accounts = accounts
            self.locale = locale
            initialDraft = TransactionEditDraft(transaction: transaction, locale: locale)
            draft = initialDraft
        }
        var hasChanges: Bool { draft != initialDraft }
    }
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case saveTapped, cancelTapped, saveCancelled
        case saved(Result<FinanceOverview, TransactionEditError>)
        case delegate(Delegate)
        case alert(PresentationAction<Alert>)
        enum Delegate: Equatable { case didSave(FinanceOverview) }
        enum Alert: Equatable { case discard }
    }
    @Dependency(\.financeClient) var client
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()
            .onChange(of: \.draft) { _, _ in
                Reduce { state, _ in
                    state.failure = nil
                    return .none
                }
            }
        Reduce { state, action in
            switch action {
            case .saveTapped:
                guard !state.isSaving, state.hasChanges else { return .none }
                let replacement: Transaction
                do { replacement = try state.draft.transaction(replacing: state.expected, locale: state.locale) }
                catch {
                    state.failure = error as? TransactionEditError ?? .saving
                    return .none
                }
                state.isSaving = true
                state.failure = nil
                let expected = state.expected
                let client = client
                let date = now
                let calendar = calendar
                return .run { send in
                    do {
                        let overview = try await client.editTransaction(expected, replacement, date, calendar)
                        // Once committed, deliver the success rather than reporting cancellation as a save failure.
                        await send(.saved(.success(overview)))
                    } catch is CancellationError { await send(.saveCancelled) }
                    catch { await send(.saved(.failure(error as? TransactionEditError ?? .saving))) }
                }
            case let .saved(.success(overview)):
                state.isSaving = false
                return .send(.delegate(.didSave(overview)))
            case let .saved(.failure(error)):
                state.isSaving = false
                state.failure = error
                return .none
            case .saveCancelled:
                state.isSaving = false
                return .none
            case .cancelTapped:
                guard !state.isSaving else { return .none }
                guard state.hasChanges else { return .run { _ in await dismiss() } }
                state.alert = AlertState {
                    TextState(.discardTransactionChanges)
                } actions: {
                    ButtonState(role: .destructive, action: .discard) { TextState(.discardChanges) }
                    ButtonState(role: .cancel) { TextState(.keepEditing) }
                } message: { TextState(.transactionChangesNotSaved) }
                return .none
            case .alert(.presented(.discard)):
                guard !state.isSaving else { return .none }
                return .run { _ in await dismiss() }
            case .binding:
                return .none
            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
