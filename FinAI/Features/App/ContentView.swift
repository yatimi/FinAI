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
            Tab(.home, systemImage: AppSymbol.home.rawValue, value: .dashboard) {
                NavigationStack {
                    DashboardView(overview: store.overview, isLoading: store.isLoading) {
                        store.send(.demoTapped)
                    }
                    .safeAreaInset(edge: .bottom) {
                        ViewThatFits(in: .horizontal) {
                            HStack {
                                analyticsLink
                                Spacer()
                                accountsLink
                            }
                            VStack(alignment: .leading, spacing: FinanceStyle.Spacing.standard) {
                                analyticsLink
                                accountsLink
                            }
                        }
                        .padding()
                        .background(FinanceStyle.Surface.card)
                    }
                    .navigationTitle(.finAI)
                    .toolbar {
                        assistantButton
                        importButton
                        refreshButton
                    }
                }
            }
            Tab(.transactions, systemImage: AppSymbol.transactions.rawValue, value: .transactions) {
                NavigationStack {
                    TransactionsView(store: store.scope(state: \.transactions, action: \.transactions))
                    .navigationTitle(.transactions)
                    .toolbar { importButton }
                }
            }
            Tab(.plan, systemImage: AppSymbol.goals.rawValue, value: .plan) {
                NavigationStack {
                    PlanView(store: store.scope(state: \.plan, action: \.plan),
                             transactions: store.overview?.snapshot.transactions,
                             openBudgets: { store.send(.budgetsTapped) },
                             openGoals: { store.send(.goalsTapped) },
                             openDebts: { store.send(.debtsTapped) },
                             addBudget: { store.send(.addBudgetTapped) },
                             addGoal: { store.send(.addGoalTapped) },
                             addDebt: { store.send(.addDebtTapped) },
                             selectBudget: { store.send(.budgetTapped($0)) },
                             selectGoal: { store.send(.goalTapped($0)) })
                }
            }
        }
        .tint(FinanceStyle.ColorRole.accent)
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
        .sheet(item: $store.scope(state: \.assistant, action: \.assistant)) { AssistantView(store: $0) }
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            TransactionDetailView(store: detailStore)
        }
        .sheet(item: $store.scope(state: \.merchantRules, action: \.merchantRules)) { MerchantRulesView(store: $0) }
        .sheet(item: $store.scope(state: \.budgets, action: \.budgets)) { BudgetsView(store: $0) }
        .sheet(item: $store.scope(state: \.goals, action: \.goals)) { GoalsView(store: $0) }
        .sheet(item: $store.scope(state: \.debts, action: \.debts)) { DebtsView(store: $0) }
        .sheet(item: $store.scope(state: \.importFlow, action: \.importFlow)) { ImportView(store: $0) }
        .task { await store.send(.task).finish() }
        .onDisappear { store.send(.cancelLoading) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.refresh) }
        }
    }

    private var analyticsLink: some View {
        NavigationLink {
            AnalyticsView(store: store)
                .navigationTitle(.analytics)
                .toolbar { refreshButton }
        } label: {
            Label(.analytics, systemImage: AppSymbol.analytics.rawValue)
        }
    }

    private var accountsLink: some View {
        NavigationLink {
            AccountsView(accounts: store.overview?.snapshot.accounts ?? [])
                .navigationTitle(.accounts)
                .toolbar {
                    Button(.merchantRules, systemImage: AppSymbol.merchantRules.rawValue) {
                        store.send(.merchantRulesTapped)
                    }
                }
        } label: {
            Label(.accounts, systemImage: AppSymbol.accounts.rawValue)
        }
    }

    private var assistantButton: some View {
        Button(.assistant, systemImage: AppSymbol.assistant.rawValue) { store.send(.assistantTapped) }
            .disabled(store.isLoading || store.overview == nil)
            .accessibilityIdentifier(AccessibilityID.openAssistant)
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
