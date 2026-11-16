//
//  WhatIfView.swift
//  FinAI
//
//  Created by Tommy on 23.10.26.
//

import ComposableArchitecture
import SwiftUI

struct WhatIfView: View {
    let store: StoreOf<ForecastFeature>
    @FocusState private var amountFocused: Bool

    var body: some View {
        List { WhatIfSection(store: store, keyboardFocus: $amountFocused) }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(FinanceStyle.Surface.canvas)
            .navigationTitle(Text(.whatIfTitle))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(.done) { amountFocused = false }
                        .accessibilityIdentifier(AccessibilityID.whatIfKeyboardDone)
                }
            }
    }
}
