//
//  Transaction.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation

struct Transaction: Identifiable, Equatable, Codable, Sendable {
    enum Kind: String, CaseIterable, Codable, Sendable {
        case expense, income, transfer, refund, adjustment, unknown
    }
    enum Direction: String, Codable, Sendable { case debit, credit }
    enum IncomeKind: String, CaseIterable, Codable, Sendable {
        case salary, freelance, bonus, interest, reimbursement, other
    }
    enum Source: String, Codable, Sendable { case demo, imported }

    let id: UUID
    let accountID: UUID
    let date: Date
    let merchant: String
    let rawDescription: String
    /// A nonnegative magnitude; direction and kind carry independent semantics.
    let money: Money
    let direction: Direction
    let kind: Kind
    let category: Category
    let incomeKind: IncomeKind?
    let source: Source

    init(
        id: UUID, accountID: UUID, date: Date, merchant: String,
        rawDescription: String, money: Money, direction: Direction,
        kind: Kind, category: Category, incomeKind: IncomeKind? = nil, source: Source
    ) throws {
        guard money.amount >= 0,
              date.timeIntervalSinceReferenceDate.isFinite,
              kind != .expense || direction == .debit,
              (kind != .income && kind != .refund) || direction == .credit,
              incomeKind == nil || kind == .income else {
            throw ValidationError.invalidTransaction
        }
        self.id = id
        self.accountID = accountID
        self.date = date
        self.merchant = merchant
        self.rawDescription = rawDescription
        self.money = money
        self.direction = direction
        self.kind = kind
        self.category = category
        self.incomeKind = incomeKind
        self.source = source
    }

    private enum CodingKeys: String, CodingKey {
        case id, accountID, date, merchant, rawDescription, money, direction, kind, category, incomeKind, source
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: c.decode(UUID.self, forKey: .id), accountID: c.decode(UUID.self, forKey: .accountID),
            date: c.decode(Date.self, forKey: .date), merchant: c.decode(String.self, forKey: .merchant),
            rawDescription: c.decode(String.self, forKey: .rawDescription), money: c.decode(Money.self, forKey: .money),
            direction: c.decode(Direction.self, forKey: .direction), kind: c.decode(Kind.self, forKey: .kind),
            category: c.decode(Category.self, forKey: .category),
            incomeKind: c.decodeIfPresent(IncomeKind.self, forKey: .incomeKind),
            source: c.decode(Source.self, forKey: .source)
        )
    }
}
