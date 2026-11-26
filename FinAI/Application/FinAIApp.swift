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
        var settingsClient = SettingsClient.liveValue
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            // Isolate UI-test preferences from the user's app and other test journeys.
            if let suite = ProcessInfo.processInfo.environment["FINAI_TEST_PREFERENCES"],
               let defaults = UserDefaults(suiteName: "FinAI.UITests.\(suite)") {
                settingsClient = .live(defaults: defaults)
            } else {
                settingsClient = SettingsClient(loadAppearance: { .system }, saveAppearance: { _ in })
            }
        }
        #endif
        let preferencesClient = settingsClient
        initialState.settings.appearance = preferencesClient.loadAppearance()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting"),
           let csv = ProcessInfo.processInfo.environment["FINAI_TEST_CSV"],
           let document = try? CSVParser().parse(csv, name: "UI test.csv") {
            var importState = ImportFeature.State(snapshot: .empty, newAccountID: UUID())
            importState.document = document
            importState.mapping = .suggested(for: document)
            initialState.importFlow = importState
        } else if ProcessInfo.processInfo.arguments.contains("--uitesting"),
                  let text = ProcessInfo.processInfo.environment["FINAI_TEST_STATEMENT"],
                  let statement = try? SparkasseStatementParser().parse(pages: text.components(separatedBy: "\u{000C}"), name: "UI test.pdf") {
            var importState = ImportFeature.State(snapshot: .empty, newAccountID: UUID())
            importState.statement = statement
            initialState.importFlow = importState
        }
        #endif
        _store = State(initialValue: Store(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.settingsClient = preferencesClient
            $0.financeClient = .live(database: database)
            $0.importClient = .live(database: database)
            $0.merchantRulesClient = .live(database: database)
            $0.budgetsClient = .live(database: database)
            $0.goalsClient = .live(database: database)
            $0.debtsClient = .live(database: database)
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--uitesting") {
                // Keep synthetic UI journeys independent of month boundaries and device time zones.
                $0.assistantClient.availability = { _ in .notEnabled }
                $0.date.now = Date(timeIntervalSince1970: 1_790_380_800)
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = .gmt
                $0.calendar = calendar
            }
            #endif
        })
    }

    var body: some Scene {
        WindowGroup { ContentView(store: store) }
    }
}
