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
        Section(.reviewBeforeSaving) {
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
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        store.send(.toggleRow(candidate.id))
                    } label: {
                        Label(.row(candidate.rowNumber), systemImage: store.excludedIDs.contains(candidate.id) ? AppSymbol.excludedImportRow.rawValue : AppSymbol.includedImportRow.rawValue)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityValue(store.excludedIDs.contains(candidate.id) ? .excluded : .included)
                    Text(candidate.description).font(.headline)
                    TextField(.merchantOrPayee, text: Binding(
                        get: { candidate.merchant },
                        set: { store.send(.merchantChanged(candidate.id, $0)) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .accessibilityLabel(.merchantOrPayee)
                    MoneyText(money: candidate.money)
                    Text(candidate.direction.title)
                    Text(candidate.date, format: .dateTime.day().month().year())
                    if candidate.isPossibleDuplicate {
                        Label(.possibleDuplicate, systemImage: AppSymbol.possibleDuplicate.rawValue)
                        ForEach(candidate.duplicateMatches) { match in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(match.reason.title).font(.subheadline.bold())
                                switch match.source {
                                case .savedTransaction: Text(.matchesASavedTransactionOnThisAccount)
                                case let .importRow(row): Text(.matchesEarlierImportRow(row))
                                }
                                Text(verbatim: match.description)
                                Text(match.date, format: .dateTime.day().month().year())
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                        Button(store.excludedIDs.contains(candidate.id) ? .keepBothTransactions : .skipThisTransaction) {
                            store.send(.toggleRow(candidate.id))
                        }
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier(AccessibilityID.duplicateDecision(row: candidate.rowNumber))
                    }
                    Menu {
                        ForEach(candidate.allowedKinds, id: \.self) { kind in
                            Button { store.send(.kindChanged(candidate.id, kind)) } label: { Text(kind.title) }
                        }
                    } label: {
                        LabeledContent(.transactionType) { Text(candidate.kind.title) }
                    }
                    Menu {
                        ForEach(Category.allCases, id: \.self) { category in
                            Button { store.send(.categoryChanged(candidate.id, category)) } label: { Text(category.title) }
                        }
                    } label: {
                        LabeledContent(.category) { Text(candidate.category.title) }
                    }
                    Button(.saveMerchantRule) { store.send(.saveRuleTapped(candidate.id)) }
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier(AccessibilityID.saveRule(row: candidate.rowNumber))
                }
                .padding(.vertical, 4)
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
