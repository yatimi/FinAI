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
                Text("Possible recurring expenses, not confirmed contracts. Matching uses at least three equal payments to the same saved merchant, on one account and in one currency. Weekly dates may vary by one day; monthly and yearly dates by three days.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if payments.isEmpty {
                Text("No regular payment patterns found. More transaction history may be needed.")
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
                        LabeledContent("Account") { Text(verbatim: account.name) }
                    }
                    LabeledContent("Interval") { Text(title(for: payment.cadence)) }
                    if payment.isSubscriptionCandidate {
                        Text("Possible subscription")
                    }
                    LabeledContent("Matching payments") { Text(payment.transactionIDs.count, format: .number) }
                    LabeledContent("First observed") { Text(payment.firstDate, format: .dateTime.day().month().year()) }
                    LabeledContent("Last observed") { Text(payment.lastDate, format: .dateTime.day().month().year()) }
                    LabeledContent("Next date from pattern") { Text(payment.expectedDate, format: .dateTime.day().month().year()) }
                    Text(payment.isStale
                         ? "Expected date has passed without a matching saved payment. This pattern may have ended, changed, or be missing imported data."
                         : "Estimated from saved activity. Future payment dates and amounts are not guaranteed.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                Text("Only positive expenses are considered. Transfers, refunds, income and future transactions are excluded. Changed amounts, missing periods and irregular groups may not be detected. The subscription label also requires every matched payment to use the Subscriptions category. Nothing is changed or scheduled automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Regular payments")
        .accessibilityIdentifier("recurringPayments")
    }

    private func title(for cadence: RecurringPayment.Cadence) -> LocalizedStringKey {
        switch cadence {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }
}
