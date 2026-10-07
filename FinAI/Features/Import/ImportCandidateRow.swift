//
//  ImportCandidateRow.swift
//  FinAI
//
//  Created by Tommy on 07.10.26.
//

import ComposableArchitecture
import SwiftUI

struct ImportCandidateRow: View {
    let store: StoreOf<ImportFeature>
    let candidate: ImportCandidate
    let compactReview: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var detailsExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                store.send(.toggleRow(candidate.id))
            } label: {
                Label(
                    .row(candidate.rowNumber),
                    systemImage: store.excludedIDs.contains(candidate.id)
                        ? AppSymbol.excludedImportRow.rawValue : AppSymbol.includedImportRow.rawValue)
            }
            .buttonStyle(.borderless)
            .accessibilityValue(store.excludedIDs.contains(candidate.id) ? .excluded : .included)
            let summaryLayout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
            summaryLayout {
                Text(verbatim: candidate.merchant).font(.headline)
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 8) }
                MoneyText(money: candidate.money)
            }
            Text(candidate.date, format: .dateTime.day().month().year())
                .font(.footnote).foregroundStyle(.secondary)
            Menu {
                ForEach(candidate.allowedKinds, id: \.self) { kind in
                    Button {
                        store.send(.kindChanged(candidate.id, kind))
                    } label: {
                        Text(kind.title)
                    }
                }
            } label: {
                LabeledContent(.transactionType) { Text(candidate.kind.title) }
            }
            Menu {
                ForEach(Category.allCases, id: \.self) { category in
                    Button {
                        store.send(.categoryChanged(candidate.id, category))
                    } label: {
                        Text(category.title)
                    }
                }
            } label: {
                LabeledContent(.category) { Text(candidate.category.title) }
            }
            if candidate.isPossibleDuplicate {
                Label(.possibleDuplicate, systemImage: AppSymbol.possibleDuplicate.rawValue)
                ForEach(candidate.duplicateMatches) { match in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(match.reason.title).font(.subheadline.bold())
                        switch match.source {
                        case .savedTransaction: Text(.matchesASavedTransactionOnThisAccount)
                        case .importRow(let row): Text(.matchesEarlierImportRow(row))
                        }
                        Text(verbatim: match.description)
                        Text(match.date, format: .dateTime.day().month().year())
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                Button(
                    store.excludedIDs.contains(candidate.id) ? .keepBothTransactions : .skipThisTransaction
                ) {
                    store.send(.toggleRow(candidate.id))
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier(AccessibilityID.duplicateDecision(row: candidate.rowNumber))
            }
            if compactReview {
                DisclosureGroup(isExpanded: $detailsExpanded) {
                    editingDetails
                } label: {
                    Text(.importRowDetails)
                        .accessibilityIdentifier(AccessibilityID.importDetails(row: candidate.rowNumber))
                }
            } else {
                editingDetails
            }
        }
        .padding(.vertical, 4)
    }

    private var editingDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(candidate.description).font(.headline)
            TextField(
                .merchantOrPayee,
                text: Binding(
                    get: { candidate.merchant },
                    set: { store.send(.merchantChanged(candidate.id, $0)) }
                )
            )
            .textFieldStyle(.roundedBorder)
            .submitLabel(.done)
            .accessibilityLabel(.merchantOrPayee)
            Text(candidate.direction.title)
            Button(.saveMerchantRule) { store.send(.saveRuleTapped(candidate.id)) }
                .buttonStyle(.borderless)
                .accessibilityIdentifier(AccessibilityID.saveRule(row: candidate.rowNumber))
        }
    }
}
