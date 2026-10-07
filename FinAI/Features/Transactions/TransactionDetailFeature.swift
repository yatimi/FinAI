//
//  TransactionDetailFeature.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TransactionDetailFeature {
    @ObservableState
    struct State: Equatable {
        var transaction: Transaction
        var accountName: String
        var accounts: [Account] = []
        var original: Transaction?
        @Presents var editor: TransactionEditFeature.State?
    }
    enum Action: Equatable {
        case closeTapped, editTapped
        case editor(PresentationAction<TransactionEditFeature.Action>)
        case delegate(Delegate)
        enum Delegate: Equatable { case didUpdate(FinanceOverview) }
    }
    @Dependency(\.locale) var locale
    @Dependency(\.dismiss) var dismiss
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .closeTapped:
                guard state.editor == nil else { return .none }
                return .run { _ in await dismiss() }
            case .editTapped:
                guard state.editor == nil else { return .none }
                state.editor = TransactionEditFeature.State(transaction: state.transaction, accounts: state.accounts, locale: locale)
                return .none
            case let .editor(.presented(.delegate(.didSave(overview)))):
                guard let transaction = overview.snapshot.transactions.first(where: { $0.id == state.transaction.id }),
                      let account = overview.snapshot.accounts.first(where: { $0.id == transaction.accountID }) else { return .none }
                state.transaction = transaction
                state.accountName = account.name
                state.accounts = overview.snapshot.accounts
                state.original = overview.snapshot.originals[transaction.id]
                state.editor = nil
                return .send(.delegate(.didUpdate(overview)))
            case .editor, .delegate: return .none
            }
        }
        .ifLet(\.$editor, action: \.editor) { TransactionEditFeature() }
    }
}
