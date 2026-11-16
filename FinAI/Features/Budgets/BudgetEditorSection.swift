//
//  BudgetEditorSection.swift
//  FinAI
//
//  Created by Tommy on 09.10.26.
//

import SwiftUI

struct BudgetEditorSection: View {
    enum Field: Hashable { case limit, currency }
    @Binding var draft: BudgetDraft
    var keyboardFocus: FocusState<Field?>.Binding

    var body: some View {
        Section(.budgetDetails) {
            Picker(.category, selection: $draft.category) {
                ForEach(Category.allCases.filter { $0 != .income && $0 != .transfers }, id: \.self) {
                    Text($0.title).tag($0)
                }
            }
            TextField(.budgetLimit, text: $draft.limit).keyboardType(.decimalPad)
                .accessibilityIdentifier(AccessibilityID.budgetLimit).focused(keyboardFocus, equals: .limit)
            TextField(.currency, text: $draft.currencyCode).textInputAutocapitalization(.characters)
                .autocorrectionDisabled().focused(keyboardFocus, equals: .currency)
        }
    }
}
