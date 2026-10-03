//
//  ImportPreviewSection.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import SwiftUI

struct ImportPreviewSection: View {
    let store: StoreOf<ImportFeature>
    let preview: ImportPreview

    var body: some View {
        Section("Review before saving") {
            Text("Selected transactions: \(store.selectedCandidates.count)")
            Text("Invalid rows to skip: \(preview.issues.count)")
            Text("Possible duplicates are unchecked. Up to three matches are shown for review. Keep both only if they are separate transactions. Unknown types are excluded from overview totals.")
                .font(.footnote)
            Text("Known merchants and categories are suggested locally. Review and correct them before saving. Changing the transaction type resets its category suggestion.")
                .font(.footnote)
            Button("Edit mapping") { store.send(.editMappingTapped) }
        }
        Section("Transactions to review") {
            ForEach(preview.candidates) { candidate in
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        store.send(.toggleRow(candidate.id))
                    } label: {
                        Label("Row \(candidate.rowNumber)", systemImage: store.excludedIDs.contains(candidate.id) ? "circle" : "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityValue(store.excludedIDs.contains(candidate.id) ? "Excluded" : "Included")
                    Text(candidate.description).font(.headline)
                    TextField("Merchant or payee", text: Binding(
                        get: { candidate.merchant },
                        set: { store.send(.merchantChanged(candidate.id, $0)) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .accessibilityLabel("Merchant or payee")
                    MoneyText(money: candidate.money)
                    Text(candidate.direction.title)
                    Text(candidate.date, format: .dateTime.day().month().year())
                    if candidate.isPossibleDuplicate {
                        Label("Possible duplicate", systemImage: "exclamationmark.triangle")
                        ForEach(candidate.duplicateMatches) { match in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(match.reason.title).font(.subheadline.bold())
                                switch match.source {
                                case .savedTransaction: Text("Matches a saved transaction on this account")
                                case let .importRow(row): Text("Matches earlier import row \(row)")
                                }
                                Text(verbatim: match.description)
                                Text(match.date, format: .dateTime.day().month().year())
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                        Button(store.excludedIDs.contains(candidate.id) ? "Keep both transactions" : "Skip this transaction") {
                            store.send(.toggleRow(candidate.id))
                        }
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier("duplicateDecision-\(candidate.rowNumber)")
                    }
                    Menu {
                        ForEach(candidate.allowedKinds, id: \.self) { kind in
                            Button { store.send(.kindChanged(candidate.id, kind)) } label: { Text(kind.title) }
                        }
                    } label: {
                        LabeledContent("Transaction type") { Text(candidate.kind.title) }
                    }
                    Menu {
                        ForEach(Category.allCases, id: \.self) { category in
                            Button { store.send(.categoryChanged(candidate.id, category)) } label: { Text(category.title) }
                        }
                    } label: {
                        LabeledContent("Category") { Text(candidate.category.title) }
                    }
                    Button("Save merchant rule") { store.send(.saveRuleTapped(candidate.id)) }
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier("saveRule-\(candidate.rowNumber)")
                }
                .padding(.vertical, 4)
            }
        }
        if !preview.issues.isEmpty {
            Section("Rows that cannot be imported") {
                ForEach(preview.issues) { issue in
                    VStack(alignment: .leading) {
                        Text("Row \(issue.rowNumber)").font(.headline)
                        Text(issue.error.message)
                    }
                }
            }
        }
    }
}
