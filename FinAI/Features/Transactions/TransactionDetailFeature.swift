//
//  TransactionDetailFeature.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture

@Reducer
struct TransactionDetailFeature {
    @ObservableState
    struct State: Equatable {
        let transaction: Transaction
        let accountName: String
    }
    enum Action: Equatable { case closeTapped }
    @Dependency(\.dismiss) var dismiss
    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .closeTapped: return .run { _ in await dismiss() }
            }
        }
    }
}
