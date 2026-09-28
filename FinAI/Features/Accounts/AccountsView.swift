//
//  AccountsView.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import SwiftUI

struct AccountsView: View {
    let accounts: [Account]
    var body: some View {
        if accounts.isEmpty {
            ContentUnavailableView("No accounts yet", systemImage: "wallet.bifold", description: Text("Explore demo data from Overview to get started."))
        } else {
            List(accounts) { account in
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name).font(.headline)
                    HStack {
                        Text(account.kind.title)
                        Text(account.currency.code)
                    }
                    .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
