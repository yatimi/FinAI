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
    @Test func ukrainianResourcesPreserveArgumentsAndSupportedFollowUps() throws {
        func ukrainian(_ resource: LocalizedStringResource) -> String {
            var resource = resource
            resource.locale = Locale(identifier: "uk_UA")
            return String(localized: resource)
        }
        #expect(ukrainian(.settings) == "Налаштування")
        #expect(ukrainian(.column(2, "Amount %@ %lld")) == "Стовпець 2: Amount %@ %lld")
        #expect(ukrainian(.row(42)) == "Рядок 42")
        #expect(ukrainian(Transaction.Kind.refund.title) == "Повернення коштів")
        let previous = AssistantQuery(kind: .spending, period: .thisMonth)
        let followUp = try AssistantFollowUp().resolve(ukrainian(.assistantFollowUpLastMonth), previous: previous)
        #expect(followUp?.period == .lastMonth)
        #expect(ukrainian(.assistantFollowUpTextExplanation).contains("А без оренди?"))
        #expect(AssistantFollowUp().isRentRefinement("А без оренди?"))
    }

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
