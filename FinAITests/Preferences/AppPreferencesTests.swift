//
//  AppPreferencesTests.swift
//  FinAITests
//
//  Created by Tommy on 17.11.26.
//

import Foundation
import Testing
@testable import FinAI

@MainActor
struct AppPreferencesTests {
    @Test func persistedAppearanceSurvivesReopeningAndSystemRemovesOverride() throws {
        let suite = "FinAI.PreferencesTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AppPreferencesStore(defaults: defaults)
        #expect(store.loadAppearance() == .system)
        defaults.set("unsupported", forKey: "appAppearance")
        #expect(store.loadAppearance() == .system)
        defaults.set("preserve", forKey: "unrelated")
        for appearance in [AppAppearance.light, .dark] {
            store.saveAppearance(appearance)
            let reopened = AppPreferencesStore(defaults: try #require(UserDefaults(suiteName: suite)))
            #expect(reopened.loadAppearance() == appearance)
        }
        store.saveAppearance(.system)
        #expect(store.loadAppearance() == .system)
        #expect(defaults.object(forKey: "appAppearance") == nil)
        #expect(defaults.string(forKey: "unrelated") == "preserve")
    }
}
