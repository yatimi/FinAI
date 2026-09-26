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
        Section("Destination account") {
            Picker("Account", selection: $store.selectedAccountID) {
                Text("New account").tag(Optional<UUID>.none)
                ForEach(store.eligibleAccounts) { account in
                    Text(account.name).tag(Optional(account.id))
                }
            }
            if store.selectedAccountID == nil {
                TextField("Account name", text: $store.newAccountName)
                    .accessibilityIdentifier("importAccountName")
                    .submitLabel(.done)
                Picker("Account kind", selection: $store.newAccountKind) {
                    ForEach(Account.Kind.allCases, id: \.self) { kind in Text(kind.title).tag(kind) }
                }
            }
            TextField("Default currency (EUR, USD…)", text: $store.mapping.currencyCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .accessibilityIdentifier("importCurrency")
        }
        Section("Column mapping") {
            columnPicker("Date column", selection: $store.mapping.dateColumn)
            columnPicker("Amount column", selection: $store.mapping.amountColumn)
            columnPicker("Description column", selection: $store.mapping.descriptionColumn)
            columnPicker("Currency column", selection: $store.mapping.currencyColumn, optional: true)
            columnPicker("Type column", selection: $store.mapping.kindColumn, optional: true)
            Text("Optional columns use the default currency and transaction type below. Type values: expense, income, transfer, refund, adjustment, unknown.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        Section("Interpretation") {
            Picker("Date format", selection: $store.mapping.dateFormat) {
                ForEach(CSVMapping.DateFormat.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            Picker("Number format", selection: $store.mapping.decimalSeparator) {
                Text(verbatim: "1,234.56").tag(CSVMapping.DecimalSeparator.dot)
                Text(verbatim: "1.234,56").tag(CSVMapping.DecimalSeparator.comma)
            }
            Picker("Money direction", selection: $store.mapping.directionRule) {
                ForEach(CSVMapping.DirectionRule.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            if store.mapping.kindColumn == -1 {
                Picker("Default transaction type", selection: $store.mapping.defaultKind) {
                    ForEach(Transaction.Kind.allCases, id: \.self) { Text($0.title).tag($0) }
                }
            }
            Text("The sign controls direction, not the transaction type. Unknown transactions are excluded from overview totals until you choose a type in the preview.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        Section("First rows") {
            ForEach(Array(document.rows.prefix(3)), id: \.number) { row in
                VStack(alignment: .leading) {
                    Text("Row \(row.number)").font(.caption)
                    Text(row.fields.joined(separator: " | ")).lineLimit(3)
                }
            }
        }
    }

    private func columnPicker(_ title: LocalizedStringKey, selection: Binding<Int>, optional: Bool = false) -> some View {
        Picker(title, selection: selection) {
            Text(optional ? "Use default" : "Choose a column").tag(-1)
            ForEach(Array(document.headers.enumerated()), id: \.offset) { index, header in
                Text("Column \(index + 1): \(header)").tag(index)
            }
        }
    }
}
