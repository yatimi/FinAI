//
//  SettingsClient.swift
//  FinAI
//
//  Created by Tommy on 17.11.26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct SettingsClient: Sendable {
    var loadAppearance: @MainActor @Sendable () -> AppAppearance = { .system }
    var saveAppearance: @MainActor @Sendable (AppAppearance) -> Void
}

extension SettingsClient: DependencyKey {
    static let liveValue = Self(
        loadAppearance: { AppPreferencesStore(defaults: .standard).loadAppearance() },
        saveAppearance: { AppPreferencesStore(defaults: .standard).saveAppearance($0) }
    )
    static let testValue = Self()

    @MainActor
    static func live(defaults: UserDefaults) -> Self {
        let store = AppPreferencesStore(defaults: defaults)
        return Self(loadAppearance: { store.loadAppearance() }, saveAppearance: { store.saveAppearance($0) })
    }
}

extension DependencyValues {
    var settingsClient: SettingsClient {
        get { self[SettingsClient.self] }
        set { self[SettingsClient.self] = newValue }
    }
}
