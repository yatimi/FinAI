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
            Text("Possible duplicates are unchecked. Include them only if they are separate transactions. Unknown types are excluded from overview totals.")
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
                    MoneyText(money: candidate.money)
                    Text(candidate.direction.title)
                    Text(candidate.date, format: .dateTime.day().month().year())
                    if candidate.isPossibleDuplicate {
                        Label("Possible duplicate", systemImage: "exclamationmark.triangle")
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
