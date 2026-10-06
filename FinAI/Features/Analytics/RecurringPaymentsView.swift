//
//  RecurringPaymentsView.swift
//  FinAI
//
//  Created by Tommy on 30.09.26.
//

import ComposableArchitecture
import SwiftUI

struct RecurringPaymentsView: View {
    let store: StoreOf<AppFeature>

    private var payments: [RecurringPayment] { store.overview?.recurringPayments ?? [] }
    private var accounts: [Account] { store.overview?.snapshot.accounts ?? [] }

    var body: some View {
        List {
            Section {
                Text(.recurringDetectionExplanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if payments.isEmpty {
                Text(.noRecurringPaymentsExplanation)
            }
            ForEach(payments) { payment in
                Section {
                    LabeledContent {
                        MoneyText(money: payment.money)
                    } label: {
                        Text(verbatim: payment.merchant)
                            .font(.headline)
                    }
                    if let account = accounts.first(where: { $0.id == payment.id.accountID }) {
                        LabeledContent(.account) { Text(verbatim: account.name) }
                    }
                    LabeledContent(.interval) { Text(title(for: payment.cadence)) }
                    if payment.isSubscriptionCandidate {
                        Text(.possibleSubscription)
                    }
                    LabeledContent(.matchingPayments) { Text(payment.transactionIDs.count, format: .number) }
                    LabeledContent(.firstObserved) { Text(payment.firstDate, format: .dateTime.day().month().year()) }
                    LabeledContent(.lastObserved) { Text(payment.lastDate, format: .dateTime.day().month().year()) }
                    LabeledContent(.nextDateFromPattern) { Text(payment.expectedDate, format: .dateTime.day().month().year()) }
                    Text(payment.isStale
                         ? .staleRecurringPaymentExplanation
                         : .recurringEstimateExplanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                Text(.recurringLimitationsExplanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(.regularPayments)
        .accessibilityIdentifier(AccessibilityID.recurringPayments)
    }

    private func title(for cadence: RecurringPayment.Cadence) -> LocalizedStringResource {
        switch cadence {
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
    }
}
