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
        var initialState = AppFeature.State()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting"),
           let csv = ProcessInfo.processInfo.environment["FINAI_TEST_CSV"],
           let document = try? CSVParser().parse(csv, name: "UI test.csv") {
            var importState = ImportFeature.State(snapshot: .empty, newAccountID: UUID())
            importState.document = document
            importState.mapping = .suggested(for: document)
            initialState.importFlow = importState
        }
        #endif
        _store = State(initialValue: Store(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.financeClient = .live(database: database)
            $0.importClient = .live(database: database)
        })
    }

    var body: some Scene {
        WindowGroup { ContentView(store: store) }
    }
}
