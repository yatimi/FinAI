//
//  DebtEditorSection.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import SwiftUI

struct DebtEditorSection: View {
    @Binding var draft: DebtDraft
    var keyboardFocus: FocusState<Bool>.Binding

    var body: some View {
        Section(.debtDetails) {
            TextField(.debtPerson, text: $draft.person).focused(keyboardFocus)
            Picker(.debtDirection, selection: $draft.direction) {
                Text(.debtIOwe).tag(PersonalDebt.Direction.iOwe)
                Text(.debtOwedToMe).tag(PersonalDebt.Direction.owedToMe)
            }
            TextField(.debtPrincipal, text: $draft.amount).focused(keyboardFocus).keyboardType(.decimalPad)
            TextField(.currency, text: $draft.currencyCode).focused(keyboardFocus)
                .textInputAutocapitalization(.characters).autocorrectionDisabled()
            DatePicker(.debtStartDate, selection: $draft.date, displayedComponents: .date)
            Toggle(.debtHasDueDate, isOn: $draft.hasDueDate)
            if draft.hasDueDate {
                DatePicker(.debtDueDate, selection: $draft.dueDate, displayedComponents: .date)
            }
        }
    }
}
