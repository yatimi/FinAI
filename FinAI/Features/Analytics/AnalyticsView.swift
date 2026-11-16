//
//  AnalyticsView.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import ComposableArchitecture
import SwiftUI

struct AnalyticsView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        AnalyticsContentView(
            store: store.scope(state: \.analytics, action: \.analytics),
            openRegularPayments: { store.isRecurringPaymentsPresented = true }
        )
        .task { store.send(.analyticsOpened) }
        .navigationDestination(isPresented: $store.isRecurringPaymentsPresented) {
            RecurringPaymentsView(store: store)
        }
    }
}
