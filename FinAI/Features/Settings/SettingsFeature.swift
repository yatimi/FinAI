//
//  SettingsFeature.swift
//  FinAI
//
//  Created by Tommy on 17.11.26.
//

import ComposableArchitecture

@Reducer
struct SettingsFeature {
    private enum CancelID { case savingAppearance }

    @ObservableState
    struct State: Equatable {
        var appearance: AppAppearance = .system
        var languageSettingsUnavailable = false
    }

    enum Action: Equatable {
        case appearanceSelected(AppAppearance)
        case languageSettingsOpened(Bool)
    }

    @Dependency(\.settingsClient) var client

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .appearanceSelected(appearance):
                guard state.appearance != appearance else { return .none }
                state.appearance = appearance
                return .run { @MainActor _ in
                    try Task.checkCancellation()
                    // The synchronous write stays on the main actor, without a suspension between check and save.
                    client.saveAppearance(appearance)
                }
                .cancellable(id: CancelID.savingAppearance, cancelInFlight: true)
            case let .languageSettingsOpened(opened):
                state.languageSettingsUnavailable = !opened
                return .none
            }
        }
    }
}
