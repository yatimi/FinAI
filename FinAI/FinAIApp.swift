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
    @State private var store = Store(initialState: AppFeature.State()) { AppFeature() }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
