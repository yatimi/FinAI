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
                if store.phase != .idle { ProgressView("Preparing import…") }
                if let error = store.error {
                    Section("Import needs attention") { Text(error.message).foregroundStyle(.red) }
                        .accessibilityIdentifier("importError")
                }
                if store.replacingDemo {
                    Section {
                        Text("Demo data will be replaced only after you confirm this import.")
                    }
                }
                if let preview = store.preview {
                    ImportPreviewSection(store: store, preview: preview)
                } else {
                    Section("CSV file") {
                        if let document = store.document {
                            Text(document.name)
                            Text("Data rows: \(document.rows.count)")
                        }
                        Button("Choose CSV file") { store.isFilePickerPresented = true }
                            .accessibilityIdentifier("chooseCSV")
                        Text("UTF-8 or UTF-16. Comma, semicolon and tab delimiters are detected automatically. Up to 2 MB and 5,000 rows.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    if let document = store.document {
                        ImportMappingSection(store: store, document: document)
                        Section {
                            Button("Preview import") { store.send(.previewTapped) }
                                .accessibilityIdentifier("previewImport")
                        }
                    }
                }
            }
            .disabled(store.phase != .idle)
            .navigationTitle(store.preview == nil ? "Import CSV" : "Review import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { store.send(.closeTapped) }.disabled(store.phase == .saving)
                }
                if store.preview != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import selected") { store.send(.importTapped) }
                            .disabled(store.selectedCandidates.isEmpty || store.phase != .idle)
                            .accessibilityIdentifier("confirmSelectedImport")
                    }
                }
            }
        }
        .interactiveDismissDisabled(store.phase == .saving)
        .alert($store.scope(state: \.alert, action: \.alert))
        .fileImporter(isPresented: $store.isFilePickerPresented, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            switch result {
            case let .success(url): store.send(.fileChosen(url))
            case let .failure(error):
                if (error as? CocoaError)?.code != .userCancelled { store.send(.fileSelectionFailed) }
            }
        }
    }
}
