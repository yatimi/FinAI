//
//  ContentView.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    @Bindable var store: StoreOf<AppFeature>
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $store.selectedTab) {
            Tab("Overview", systemImage: "chart.bar", value: .dashboard) {
                NavigationStack {
                    DashboardView(overview: store.overview, isLoading: store.isLoading) {
                        store.send(.demoTapped)
                    }
                    .navigationTitle("FinAI")
                    .toolbar { importButton; refreshButton }
                }
            }
            Tab("Transactions", systemImage: "list.bullet.rectangle", value: .transactions) {
                NavigationStack {
                    TransactionsView(store: store.scope(state: \.transactions, action: \.transactions))
                    .navigationTitle("Transactions")
                    .toolbar { importButton }
                }
            }
            Tab("Analytics", systemImage: "chart.pie", value: .analytics) {
                NavigationStack {
                    AnalyticsView(analytics: store.overview?.spending)
                        .navigationTitle("Analytics")
                        .toolbar { refreshButton }
                }
            }
            Tab("Accounts", systemImage: "wallet.bifold", value: .accounts) {
                NavigationStack {
                    AccountsView(accounts: store.overview?.snapshot.accounts ?? [])
                        .navigationTitle("Accounts")
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let failure = store.failure {
                VStack(spacing: 8) {
                    Text(failure == .loading
                         ? "Unable to load local data. Your saved data has not been replaced."
                         : "Unable to save demo data. Please try again.")
                    Button("Try again") { store.send(.refresh) }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
                .accessibilityIdentifier("dataError")
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            TransactionDetailView(store: detailStore)
        }
        .sheet(item: $store.scope(state: \.importFlow, action: \.importFlow)) { ImportView(store: $0) }
        .task { await store.send(.task).finish() }
        .onDisappear { store.send(.cancelLoading) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.refresh) }
        }
    }

    private var importButton: some View {
        Button("Import CSV", systemImage: "square.and.arrow.down") { store.send(.importTapped) }
            .disabled(store.isLoading || store.overview == nil)
            .accessibilityIdentifier("openImport")
    }

    private var refreshButton: some View {
        Button("Refresh", systemImage: "arrow.clockwise") { store.send(.refresh) }
            .disabled(store.isLoading)
    }
}
