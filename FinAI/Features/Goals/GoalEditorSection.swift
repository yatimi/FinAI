//
//  GoalEditorSection.swift
//  FinAI
//
//  Created by Tommy on 08.10.26.
//

import SwiftUI

struct GoalEditorSection: View {
    enum Field: Hashable { case name, target, saved, currency }
    @Binding var draft: GoalDraft
    var keyboardFocus: FocusState<Field?>.Binding

    var body: some View {
        Section(.goalDetails) {
            TextField(.goalName, text: $draft.name).accessibilityIdentifier(AccessibilityID.goalName)
                .focused(keyboardFocus, equals: .name)
            TextField(.goalTargetAmount, text: $draft.target).keyboardType(.decimalPad)
                .accessibilityIdentifier(AccessibilityID.goalTarget).focused(keyboardFocus, equals: .target)
            TextField(.goalSavedAmount, text: $draft.saved).keyboardType(.decimalPad)
                .accessibilityIdentifier(AccessibilityID.goalSaved).focused(keyboardFocus, equals: .saved)
            TextField(.currency, text: $draft.currencyCode).textInputAutocapitalization(.characters)
                .autocorrectionDisabled().focused(keyboardFocus, equals: .currency)
            DatePicker(.goalDeadline, selection: $draft.deadline, displayedComponents: .date)
        }
    }
}
