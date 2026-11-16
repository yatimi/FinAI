//
//  DebtStore.swift
//  FinAI
//
//  Created by Tommy on 25.10.26.
//

import Foundation
import SwiftData

struct DebtStore {
    func load(in context: ModelContext, date: Date, calendar: Calendar) throws -> [PersonalDebt] {
        try Task.checkCancellation()
        let records = try context.fetch(FetchDescriptor<DebtRecord>())
        let repayments = try context.fetch(FetchDescriptor<DebtRepaymentRecord>())
        guard repayments.allSatisfy({ repayment in records.contains { $0.id == repayment.debtID } }) else {
            throw PersonalDebt.DebtError.invalid
        }
        var debts: [PersonalDebt] = []
        for record in records {
            let matching = repayments.filter { $0.debtID == record.id }
            var values = try matching.map { try $0.domainValue() }
            values.sort { $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date < $1.date }
            let debt = try record.domainValue(repayments: values)
            _ = try DebtPlanningService().progress(for: debt, on: date, calendar: calendar)
            debts.append(debt)
        }
        return debts.sorted { $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date > $1.date }
    }

    func save(_ debt: PersonalDebt, expected: PersonalDebt?, in context: ModelContext, date: Date, calendar: Calendar) throws -> [PersonalDebt] {
        _ = try DebtPlanningService().progress(for: debt, on: date, calendar: calendar)
        let existing = try load(in: context, date: date, calendar: calendar)
        guard expected == nil || expected?.id == debt.id,
              existing.first(where: { $0.id == debt.id }) == expected else { throw PersonalDebt.DebtError.changed }
        // Existing obligations are immutable; only one validated repayment may be appended.
        if let expected {
            guard debt.repayments.count == expected.repayments.count + 1,
                  Array(debt.repayments.dropLast()) == expected.repayments,
                  PersonalDebt(id: debt.id, person: debt.person, direction: debt.direction,
                               principal: debt.principal, date: debt.date, dueDate: debt.dueDate,
                               repayments: expected.repayments) == expected else { throw PersonalDebt.DebtError.invalid }
        } else {
            guard debt.repayments.isEmpty else { throw PersonalDebt.DebtError.invalid }
        }
        let repaymentRecords = try context.fetch(FetchDescriptor<DebtRepaymentRecord>())
        if let repayment = debt.repayments.last, expected != nil {
            guard !repaymentRecords.contains(where: { $0.id == repayment.id }) else { throw PersonalDebt.DebtError.changed }
        }
        do {
            if expected == nil { context.insert(DebtRecord(debt)) }
            else if let repayment = debt.repayments.last { context.insert(DebtRepaymentRecord(repayment, debtID: debt.id)) }
            try Task.checkCancellation()
            try context.save()
        } catch { context.rollback(); throw error }
        // No cancellation check after commit: callers must receive the committed result.
        var saved = debt
        saved.repayments.sort { $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date < $1.date }
        return (existing.filter { $0.id != debt.id } + [saved]).sorted {
            $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date > $1.date
        }
    }
}
