//
//  ImportMappingSection.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import SwiftUI

struct ImportMappingSection: View {
    @Bindable var store: StoreOf<ImportFeature>
    let document: CSVDocument

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
            TextField(.defaultCurrencyEurUsd, text: $store.mapping.currencyCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .accessibilityIdentifier(AccessibilityID.importCurrency)
        }
        Section(.columnMapping) {
            columnPicker(.dateColumn, selection: $store.mapping.dateColumn)
            columnPicker(.amountColumn, selection: $store.mapping.amountColumn)
            columnPicker(.descriptionColumn, selection: $store.mapping.descriptionColumn)
            columnPicker(.currencyColumn, selection: $store.mapping.currencyColumn, optional: true)
            columnPicker(.typeColumn, selection: $store.mapping.kindColumn, optional: true)
            Text(.optionalImportColumnsExplanation)
                .font(.footnote).foregroundStyle(.secondary)
        }
        Section(.interpretation) {
            Picker(.dateFormat, selection: $store.mapping.dateFormat) {
                ForEach(CSVMapping.DateFormat.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            Picker(.numberFormat, selection: $store.mapping.decimalSeparator) {
                Text(verbatim: "1,234.56").tag(CSVMapping.DecimalSeparator.dot)
                Text(verbatim: "1.234,56").tag(CSVMapping.DecimalSeparator.comma)
            }
            Picker(.moneyDirection, selection: $store.mapping.directionRule) {
                ForEach(CSVMapping.DirectionRule.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            if store.mapping.kindColumn == -1 {
                Picker(.defaultTransactionType, selection: $store.mapping.defaultKind) {
                    ForEach(Transaction.Kind.allCases, id: \.self) { Text($0.title).tag($0) }
                }
            }
            Text(.importDirectionExplanation)
                .font(.footnote).foregroundStyle(.secondary)
        }
        Section(.firstRows) {
            ForEach(Array(document.rows.prefix(3)), id: \.number) { row in
                VStack(alignment: .leading) {
                    Text(.row(row.number)).font(.caption)
                    Text(row.fields.joined(separator: " | ")).lineLimit(3)
                }
            }
        }
    }

    private func columnPicker(_ title: LocalizedStringResource, selection: Binding<Int>, optional: Bool = false) -> some View {
        Picker(title, selection: selection) {
            Text(optional ? .useDefault : .chooseAColumn).tag(-1)
            ForEach(Array(document.headers.enumerated()), id: \.offset) { index, header in
                Text(.column(index + 1, header)).tag(index)
            }
        }
    }
}
