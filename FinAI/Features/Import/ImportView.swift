//
//  ImportView.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import ComposableArchitecture
import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Bindable var store: StoreOf<ImportFeature>

    var body: some View {
        NavigationStack {
            Form {
                if store.phase != .idle { ProgressView(.preparingImport) }
                if let error = store.error {
                    Section(.importNeedsAttention) { Text(error.message).foregroundStyle(.red) }
                        .accessibilityIdentifier(AccessibilityID.importError)
                }
                if store.replacingDemo {
                    Section {
                        Text(.demoDataWillBeReplacedOnlyAfterYouConfirmThisImport)
                    }
                }
                if let preview = store.preview {
                    ImportPreviewSection(store: store, preview: preview)
                } else {
                    Section(.importFile) {
                        if let name = store.sourceName {
                            Text(verbatim: name)
                            Text(.dataRows(store.sourceRowCount))
                        }
                        Button(.chooseImportFile) { store.isFilePickerPresented = true }
                            .accessibilityIdentifier(AccessibilityID.chooseCSV)
                        Text(.importFileRequirementsExplanation)
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    if store.sourceName != nil {
                        ImportAccountSection(store: store)
                        if let document = store.document {
                            ImportMappingSection(store: store, document: document)
                        }
                        if store.statement != nil {
                            Section { Text(.statementReviewExplanation).font(.footnote) }
                        }
                        Section {
                            Button(.previewImport) { store.send(.previewTapped) }
                                .accessibilityIdentifier(AccessibilityID.previewImport)
                        }
                    }
                }
            }
            .disabled(store.phase != .idle)
            .navigationTitle(store.preview == nil ? .importTransactions : .reviewImport)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.close) { store.send(.closeTapped) }.disabled(store.phase == .saving)
                }
                if store.preview != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(.importSelected) { store.send(.importTapped) }
                            .disabled(store.selectedCandidates.isEmpty || store.phase != .idle)
                            .accessibilityIdentifier(AccessibilityID.confirmSelectedImport)
                    }
                }
            }
        }
        .sheet(item: $store.scope(state: \.merchantRules, action: \.merchantRules)) { MerchantRulesView(store: $0) }
        .interactiveDismissDisabled(store.phase == .saving)
        .alert($store.scope(state: \.alert, action: \.alert))
        .fileImporter(isPresented: $store.isFilePickerPresented, allowedContentTypes: [.commaSeparatedText, .plainText, .pdf]) { result in
            switch result {
            case let .success(url): store.send(.fileChosen(url))
            case let .failure(error):
                if (error as? CocoaError)?.code != .userCancelled { store.send(.fileSelectionFailed) }
            }
        }
    }
}
