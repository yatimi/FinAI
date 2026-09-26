//
//  AccountRecord.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import Foundation
import SwiftData

@Model
final class AccountRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var kind: String
    var currencyCode: String

    init(_ account: Account) {
        id = account.id
        name = account.name
        kind = account.kind.rawValue
        currencyCode = account.currency.code
    }

    func domainValue() throws -> Account {
        guard let kind = Account.Kind(rawValue: kind) else { throw ValidationError.invalidSnapshot }
        return try Account(id: id, name: name, kind: kind, currency: Currency(code: currencyCode))
    }
}
