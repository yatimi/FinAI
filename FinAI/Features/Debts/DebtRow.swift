//
//  DebtRow.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import SwiftUI

struct DebtRow: View {
    let debt: PersonalDebt
    let progress: DebtProgress?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(debt.direction == .iOwe ? .debtIOwe : .debtOwedToMe).foregroundStyle(.secondary)
            DebtAmountRow(title: .debtPrincipal, money: debt.principal)
            LabeledContent(.debtStartDate) { Text(debt.date, format: .dateTime.day().month().year()) }
            if let due = debt.dueDate {
                LabeledContent(.debtDueDate) { Text(due, format: .dateTime.day().month().year()) }
            }
            if let progress {
                DebtAmountRow(title: .debtRepaid, money: progress.repaid)
                DebtAmountRow(title: .debtRemaining, money: progress.remaining)
                Text(progress.status == .settled ? .debtSettled : progress.status == .overdue ? .debtOverdue : .debtActive)
                    .foregroundStyle(.secondary)
            }
            if !debt.repayments.isEmpty {
                Text(.debtRepaymentHistory).font(.headline)
                ForEach(debt.repayments) { repayment in
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Text(repayment.date, format: .dateTime.day().month().year())
                            Spacer()
                            MoneyText(money: repayment.amount)
                        }
                        VStack(alignment: .leading) {
                            Text(repayment.date, format: .dateTime.day().month().year())
                            MoneyText(money: repayment.amount)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}
