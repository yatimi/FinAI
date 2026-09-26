//
//  DashboardView.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import SwiftUI

struct DashboardView: View {
    let overview: FinanceOverview?
    let isLoading: Bool
    let loadDemo: () -> Void

    var body: some View {
        Group {
            if let overview {
                if overview.snapshot.accounts.isEmpty {
                    ContentUnavailableView {
                        Label("Understand your finances", systemImage: "chart.bar.doc.horizontal")
                    } description: {
                        Text("Start with synthetic data to explore accounts, transactions and a monthly overview.")
                    } actions: {
                        Button("Explore demo", action: loadDemo)
                            .buttonStyle(.borderedProminent)
                            .disabled(isLoading)
                            .accessibilityIdentifier("loadDemo")
                    }
                } else {
                    List {
                        Section {
                            Label("Demo data · stored on this device", systemImage: "internaldrive")
                                .font(.subheadline)
                            Text(overview.month, format: .dateTime.month(.wide).year())
                                .font(.title2.bold())
                        }
                        ForEach(overview.summaries) { summary in
                            Section(summary.currency.code) {
                                metric("Income", money: summary.income)
                                metric("Expenses", money: summary.expenses)
                                metric("Refunds", money: summary.refunds)
                                metric("Net spending", money: summary.netSpending)
                                metric("Net flow", money: summary.netFlow)
                            }
                        }
                        if overview.summaries.isEmpty {
                            Text("No transactions this month.")
                        }
                        Section {
                            Text("Net spending is expenses minus refunds. Net flow is income minus net spending. Transfers, adjustments and unknown transactions are excluded. These totals are not account balances.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("dashboard")
                }
            } else if isLoading {
                ProgressView("Loading local data…")
            } else {
                ContentUnavailableView("Local data unavailable", systemImage: "externaldrive.badge.exclamationmark")
            }
        }
        .overlay(alignment: .topTrailing) {
            if isLoading && overview != nil { ProgressView().padding().accessibilityLabel("Loading local data…") }
        }
    }

    private func metric(_ title: LocalizedStringKey, money: Money) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack { Text(title); Spacer(); MoneyText(money: money) }
            VStack(alignment: .leading) { Text(title); MoneyText(money: money) }
        }
        .accessibilityElement(children: .combine)
    }
}
