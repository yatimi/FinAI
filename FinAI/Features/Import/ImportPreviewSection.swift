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
    @State private var compactReview = true

    var body: some View {
        Section(.reviewBeforeSaving) {
            Toggle(.compactReview, isOn: $compactReview)
                .accessibilityIdentifier(AccessibilityID.compactImportReview)
            if store.statement != nil { Text(.statementReviewExplanation).font(.footnote) }
            Text(.selectedTransactions(store.selectedCandidates.count))
            Text(.invalidRowsToSkip(preview.issues.count))
            Text(.duplicateReviewExplanation)
                .font(.footnote)
            Text(.merchantSuggestionsExplanation)
                .font(.footnote)
            Button(store.statement == nil ? .editMapping : .editImportAccount) { store.send(.editMappingTapped) }
        }
        Section(.transactionsToReview) {
            ForEach(preview.candidates) { candidate in
                ImportCandidateRow(store: store, candidate: candidate, compactReview: compactReview)
            }
        }
        if !preview.issues.isEmpty {
            Section(.rowsThatCannotBeImported) {
                ForEach(preview.issues) { issue in
                    VStack(alignment: .leading) {
                        Text(.row(issue.rowNumber)).font(.headline)
                        Text(issue.error.message)
                    }
                }
            }
        }
    }
}
