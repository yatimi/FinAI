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
            Tab(.overview, systemImage: AppSymbol.overview.rawValue, value: .dashboard) {
                NavigationStack {
                    DashboardView(overview: store.overview, isLoading: store.isLoading) {
                        store.send(.demoTapped)
                    }
                    .navigationTitle(.finAI)
                    .toolbar { importButton; refreshButton }
                }
            }
            Tab(.transactions, systemImage: AppSymbol.transactions.rawValue, value: .transactions) {
                NavigationStack {
                    TransactionsView(store: store.scope(state: \.transactions, action: \.transactions))
                    .navigationTitle(.transactions)
                    .toolbar { importButton }
                }
            }
            Tab(.analytics, systemImage: AppSymbol.analytics.rawValue, value: .analytics) {
                NavigationStack {
                    AnalyticsView(store: store)
                        .navigationTitle(.analytics)
                        .toolbar { refreshButton }
                }
            }
            Tab(.accounts, systemImage: AppSymbol.accounts.rawValue, value: .accounts) {
                NavigationStack {
                    AccountsView(accounts: store.overview?.snapshot.accounts ?? [])
                        .navigationTitle(.accounts)
                        .toolbar {
                            Button(.merchantRules, systemImage: AppSymbol.merchantRules.rawValue) { store.send(.merchantRulesTapped) }
                        }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let failure = store.failure {
                VStack(spacing: 8) {
                    Text(failure == .loading
                         ? .unableToLoadLocalDataYourSavedDataHasNotBeenReplaced
                         : .unableToSaveDemoDataPleaseTryAgain)
                    Button(.tryAgain) { store.send(.refresh) }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
                .accessibilityIdentifier(AccessibilityID.dataError)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            TransactionDetailView(store: detailStore)
        }
        .sheet(item: $store.scope(state: \.merchantRules, action: \.merchantRules)) { MerchantRulesView(store: $0) }
        .sheet(item: $store.scope(state: \.importFlow, action: \.importFlow)) { ImportView(store: $0) }
        .task { await store.send(.task).finish() }
        .onDisappear { store.send(.cancelLoading) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.refresh) }
        }
    }

    private var importButton: some View {
        Button(.importTransactions, systemImage: AppSymbol.importFile.rawValue) { store.send(.importTapped) }
            .disabled(store.isLoading || store.overview == nil)
            .accessibilityIdentifier(AccessibilityID.openImport)
    }

    private var refreshButton: some View {
        Button(.refresh, systemImage: AppSymbol.refresh.rawValue) { store.send(.refresh) }
            .disabled(store.isLoading)
    }
}
