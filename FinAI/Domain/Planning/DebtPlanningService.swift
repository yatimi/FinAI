//
//  DebtPlanningService.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import Foundation

struct DebtPlanningService {
    func progress(for debt: PersonalDebt, on date: Date, calendar: Calendar) throws -> DebtProgress {
        guard date.timeIntervalSinceReferenceDate.isFinite,
              debt.date.timeIntervalSinceReferenceDate.isFinite,
              !debt.person.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              debt.person.count <= 200, debt.principal.amount > 0 else { throw PersonalDebt.DebtError.invalid }
        if let due = debt.dueDate {
            guard due.timeIntervalSinceReferenceDate.isFinite,
                  calendar.startOfDay(for: due) >= calendar.startOfDay(for: debt.date) else {
                throw PersonalDebt.DebtError.invalid
            }
        }
        guard calendar.startOfDay(for: debt.date) <= calendar.startOfDay(for: date),
              Set(debt.repayments.map(\.id)).count == debt.repayments.count else { throw PersonalDebt.DebtError.invalid }
        var repaid = Money.zero(debt.principal.currency)
        for repayment in debt.repayments {
            guard repayment.amount.amount > 0, repayment.date.timeIntervalSinceReferenceDate.isFinite,
                  calendar.startOfDay(for: repayment.date) >= calendar.startOfDay(for: debt.date),
                  calendar.startOfDay(for: repayment.date) <= calendar.startOfDay(for: date) else {
                throw PersonalDebt.DebtError.invalid
            }
            repaid = try repaid.adding(repayment.amount)
        }
        guard repaid.amount <= debt.principal.amount else { throw PersonalDebt.DebtError.overpayment }
        let remaining = try debt.principal.subtracting(repaid)
        let overdue = debt.dueDate.map { calendar.startOfDay(for: $0) < calendar.startOfDay(for: date) } ?? false
        return DebtProgress(repaid: repaid, remaining: remaining,
                            status: remaining.amount == 0 ? .settled : overdue ? .overdue : .active)
    }

    func adding(_ repayment: DebtRepayment, to debt: PersonalDebt, on date: Date, calendar: Calendar) throws -> PersonalDebt {
        var updated = debt
        updated.repayments.append(repayment)
        _ = try progress(for: updated, on: date, calendar: calendar)
        return updated
    }
}
