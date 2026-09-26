//
//  AppFeature.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action {}
    var body: some ReducerOf<Self> { EmptyReducer() }
}
