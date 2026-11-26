//
//  SettingsFeatureTests.swift
//  FinAITests
//
//  Created by Tommy on 17.11.26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import FinAI

@MainActor
struct SettingsFeatureTests {
    @Test func changesPersistAndSelectingCurrentAppearanceDoesNotWrite() async {
        var saved: [AppAppearance] = []
        let store = TestStore(initialState: SettingsFeature.State()) { SettingsFeature() } withDependencies: {
            $0.settingsClient.saveAppearance = { saved.append($0) }
        }
        await store.send(.appearanceSelected(.system))
        #expect(saved.isEmpty)
        await store.send(.appearanceSelected(.dark)) { $0.appearance = .dark }.finish()
        await store.send(.appearanceSelected(.dark))
        #expect(saved == [.dark])
        await store.send(.appearanceSelected(.light)) { $0.appearance = .light }.finish()
        await store.send(.appearanceSelected(.system)) { $0.appearance = .system }.finish()
        #expect(saved == [.dark, .light, .system])
    }

    @Test func failedLanguageSettingsCanBeRetried() async {
        let store = TestStore(initialState: SettingsFeature.State()) { SettingsFeature() }
        await store.send(.languageSettingsOpened(false)) { $0.languageSettingsUnavailable = true }
        await store.send(.languageSettingsOpened(true)) { $0.languageSettingsUnavailable = false }
    }

    @Test func dismissingSettingsKeepsAppearanceAndFinancialState() async {
        var state = AppFeature.State()
        state.settings.appearance = .dark
        let store = TestStore(initialState: state) { AppFeature() }
        await store.send(.binding(.set(\.isSettingsPresented, true))) { $0.isSettingsPresented = true }
        await store.send(.binding(.set(\.isSettingsPresented, false))) { $0.isSettingsPresented = false }
        #expect(store.state == state)
    }
}
