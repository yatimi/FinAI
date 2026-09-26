//
//  FinAIApp.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import SwiftUI

@main
struct FinAIApp: App {
    @State private var store: StoreOf<AppFeature>

    init() {
        let database = FinanceDatabase(inMemory: ProcessInfo.processInfo.arguments.contains("--uitesting"))
        _store = State(initialValue: Store(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.financeClient = .live(database: database)
        })
    }

    var body: some Scene {
        WindowGroup { ContentView(store: store) }
    }
}
