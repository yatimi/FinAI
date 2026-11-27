//
//  AppPreferencesStore.swift
//  FinAI
//
//  Created by Tommy on 17.11.26.
//

import Foundation

@MainActor
struct AppPreferencesStore {
    let defaults: UserDefaults
    private static let appearanceKey = "appAppearance"

    func loadAppearance() -> AppAppearance {
        defaults.string(forKey: Self.appearanceKey).flatMap(AppAppearance.init(rawValue:)) ?? .system
    }

    func saveAppearance(_ appearance: AppAppearance) {
        if appearance == .system {
            defaults.removeObject(forKey: Self.appearanceKey)
        } else {
            defaults.set(appearance.rawValue, forKey: Self.appearanceKey)
        }
    }
}
