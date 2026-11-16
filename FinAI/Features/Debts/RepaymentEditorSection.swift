//
//  RepaymentEditorSection.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import SwiftUI

struct RepaymentEditorSection: View {
    @Binding var draft: RepaymentDraft
    let debt: PersonalDebt
    let progress: DebtProgress?
    var keyboardFocus: FocusState<Bool>.Binding

    var body: some View {
        Section(.recordDebtRepayment) {
            Text(verbatim: debt.person).font(.headline)
            Text(verbatim: debt.principal.currency.code)
            if let progress { DebtAmountRow(title: .debtRemaining, money: progress.remaining) }
            TextField(.debtRepaymentAmount, text: $draft.amount)
                .keyboardType(.decimalPad).focused(keyboardFocus)
            DatePicker(.debtRepaymentDate, selection: $draft.date, displayedComponents: .date)
        }
    }
}
