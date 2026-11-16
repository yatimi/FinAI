//
//  ImportAccountSection.swift
//  FinAI
//
//  Created by Tommy on 06.10.26.
//

import ComposableArchitecture
import SwiftUI

struct ImportAccountSection: View {
    @Bindable var store: StoreOf<ImportFeature>

    var body: some View {
        Section(.destinationAccount) {
            Picker(.account, selection: $store.selectedAccountID) {
                Text(.newAccount).tag(Optional<UUID>.none)
                ForEach(store.eligibleAccounts) { account in
                    Text(account.name).tag(Optional(account.id))
                }
            }
            if store.selectedAccountID == nil {
                TextField(.accountName, text: $store.newAccountName)
                    .accessibilityIdentifier(AccessibilityID.importAccountName)
                    .submitLabel(.done)
                Picker(.accountKind, selection: $store.newAccountKind) {
                    ForEach(Account.Kind.allCases, id: \.self) { kind in Text(kind.title).tag(kind) }
                }
            }
            if let statement = store.statement {
                Text(.statementCurrency(statement.currency.code))
            } else {
                TextField(.defaultCurrencyEurUsd, text: $store.mapping.currencyCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier(AccessibilityID.importCurrency)
            }
        }
    }
}
