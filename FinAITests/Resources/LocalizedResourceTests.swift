//
//  LocalizedResourceTests.swift
//  FinAI
//
//  Created by Tommy on 04.10.26.
//

import Foundation
import Testing
@testable import FinAI

struct LocalizedResourceTests {
    @Test func importLoadingMessageIsReadableInsteadOfTheResourceKey() {
        #expect(english(.preparingImport) == "Preparing import…")
    }

    @Test func importConfirmationKeepsCountsAndPrivacyMessage() {
        #expect(english(.importConfirmationMessage(2, 1)) == "Selected: 2. Skipped: 1. Your source file will not be changed.")
        #expect(english(.demoImportConfirmationMessage(0, 3)) == "Demo data will be replaced. Selected: 0. Skipped: 3. Your source file will not be changed.")
    }

    @Test func importedHeaderIsAnArgumentRatherThanAFormatString() {
        #expect(english(.column(2, "Amount %@ %lld")) == "Column 2: Amount %@ %lld")
        #expect(english(.categoryBreakdownHeading("EUR")) == "By category · EUR")
        #expect(english(.row(42)) == "Row 42")
    }

    @Test func domainLabelsAndImportFailuresResolveFromAppCatalog() {
        #expect(english(Transaction.Kind.refund.title) == "Refund")
        #expect(english(Category.housing.title) == "Housing")
        #expect(english(ImportError.storageChanged.message) == "The import could not be saved. Your previous data is preserved. Try again or reopen the import.")
    }

    private func english(_ resource: LocalizedStringResource) -> String {
        var resource = resource
        resource.locale = Locale(identifier: "en_US")
        return String(localized: resource)
    }
}
