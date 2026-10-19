//
//  AssistantView.swift
//  FinAI
//
//  Created by Tommy on 18.10.26.
//

import ComposableArchitecture
import SwiftUI

struct AssistantView: View {
    @Bindable var store: StoreOf<AssistantFeature>
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(.assistantIntroduction)
                    Text(.assistantPrivacyExplanation).font(.footnote).foregroundStyle(.secondary)
                }
                Section(.assistantSuggestedQuestions) {
                    Button(.assistantThisMonthQuestion) { store.send(.suggested(AssistantQuery(kind: .spending))) }
                        .accessibilityIdentifier(AccessibilityID.assistantThisMonth)
                    Button(.assistantLastMonthQuestion) { store.send(.suggested(AssistantQuery(kind: .spending, period: .lastMonth))) }
                    Button(.assistantCompareQuestion) { store.send(.suggested(AssistantQuery(kind: .comparison))) }
                        .accessibilityIdentifier(AccessibilityID.assistantCompare)
                    if !store.merchants.isEmpty {
                        Menu {
                            ForEach(store.merchants, id: \.self) { merchant in
                                Button(merchant) { store.send(.suggested(AssistantQuery(kind: .merchant, merchant: merchant))) }
                            }
                        } label: { Text(.assistantMerchantQuestion) }
                    }
                }
                Section(.assistantYourQuestion) {
                    if store.availability == .available || store.previousQuery != nil {
                        TextField(.assistantQuestionPlaceholder, text: $store.question, axis: .vertical)
                            .lineLimit(2...5)
                            .accessibilityIdentifier(AccessibilityID.assistantQuestion)
                        Text(.assistantQuestionLimit).font(.footnote).foregroundStyle(.secondary)
                        if store.availability != .available {
                            Text(.assistantFollowUpTextExplanation).font(.footnote).foregroundStyle(.secondary)
                        }
                        Button(.assistantAsk) { store.send(.askTapped) }
                            .disabled(store.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.question.count > 1_000)
                            .accessibilityIdentifier(AccessibilityID.assistantAsk)
                    } else {
                        Text(availabilityExplanation)
                        Button(.assistantCheckAvailability) { store.send(.task) }
                    }
                }
                if store.isLoading {
                    Section {
                        ProgressView().accessibilityLabel(.assistantWorking)
                        Button(.cancel) { store.send(.cancelTapped) }
                    }
                }
                if let failure = store.failure {
                    Section { Text(errorExplanation(failure)).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle(.assistant)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.assistantClear) { store.send(.clearTapped) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.done) { store.send(.closeTapped) }
                }
            }
            .navigationDestination(isPresented: $store.isAnswerPresented) {
                answerContent
            }
            .sheet(item: $store.scope(state: \.detail, action: \.detail)) { TransactionDetailView(store: $0) }
        }
        .task { store.send(.task) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.task) }
        }
    }

    private var answerContent: some View {
        List {
            if let answer = store.answer {
                Section(.assistantFollowUp) {
                    Text(.assistantFollowUpExplanation).font(.footnote).foregroundStyle(.secondary)
                    Button(answer.query.period == .thisMonth ? .assistantFollowUpLastMonth : .assistantFollowUpThisMonth) {
                        store.send(.followUp(answer.query.period == .thisMonth ? .lastMonth : .thisMonth))
                    }
                    .accessibilityIdentifier(AccessibilityID.assistantFollowUpPeriod)
                }
                AssistantAnswerView(answer: answer) { month, currency in
                    store.send(.showTransactions(month, currency))
                }
            }
            if store.isLoading {
                Section {
                    ProgressView().accessibilityLabel(.assistantWorking)
                    Button(.cancel) { store.send(.cancelTapped) }
                }
            }
        }
        .navigationTitle(.assistantAnswer)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(.assistantClear) { store.send(.clearTapped) }
            }
        }
        .navigationDestination(isPresented: $store.isDrilldownPresented) {
            AssistantTransactionsView(store: store)
        }
    }

    private var availabilityExplanation: LocalizedStringResource {
        switch store.availability {
        case .available: .assistantIntroduction
        case .deviceNotSupported: .assistantDeviceUnavailable
        case .notEnabled: .assistantEnableIntelligence
        case .notReady: .assistantModelNotReady
        case .unsupportedLanguage: .assistantLanguageUnavailable
        }
    }

    private func errorExplanation(_ error: AssistantError) -> LocalizedStringResource {
        switch error {
        case .unsupportedQuestion: .assistantUnsupportedQuestion
        case .merchantNotFound, .ambiguousMerchant: .assistantChooseSavedMerchant
        case .modelUnavailable: .assistantModelUnavailable
        case .interpretationFailed: .assistantInterpretationFailed
        case .calculationFailed: .assistantCalculationFailed
        }
    }
}
