//
//  SettingsView.swift
//  FinAI
//
//  Created by Tommy on 17.11.26.
//

import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>
    let close: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(.settingsAppearance, selection: Binding(
                        get: { store.appearance },
                        set: { store.send(.appearanceSelected($0)) }
                    )) {
                        ForEach(AppAppearance.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .accessibilityIdentifier(AccessibilityID.settingsAppearance)
                } header: { Text(.settingsAppearance) } footer: { Text(.settingsAppearanceExplanation) }

                Section {
                    LabeledContent(.settingsLanguage) {
                        Text(verbatim: Bundle.main.preferredLocalizations.first == "uk" ? "Українська" : "English")
                    }
                    Button(.settingsOpenLanguage) { openLanguageSettings() }
                        .accessibilityIdentifier(AccessibilityID.settingsLanguage)
                    if store.languageSettingsUnavailable { Text(.settingsLanguageUnavailable) }
                } header: { Text(.settingsLanguage) } footer: { Text(.settingsLanguageExplanation) }

                Section {
                    NavigationLink {
                        PrivacyView()
                    } label: {
                        Label(.settingsPrivacy, systemImage: AppSymbol.privacy.rawValue)
                    }
                    .accessibilityIdentifier(AccessibilityID.settingsPrivacy)
                }
            }
            .navigationTitle(.settings)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.done, action: close).accessibilityIdentifier(AccessibilityID.closeSettings)
                }
            }
        }
        .preferredColorScheme(store.appearance.colorScheme)
    }

    private func openLanguageSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            store.send(.languageSettingsOpened(false))
            return
        }
        openURL(url) { store.send(.languageSettingsOpened($0)) }
    }
}
