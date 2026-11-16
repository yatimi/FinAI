//
//  StatementFixtures.swift
//  FinAITests
//
//  Created by Tommy on 06.10.26.
//

import Foundation
@testable import FinAI

/// Entirely synthetic statement content; no real account or transaction data.
enum StatementFixtures {
    static func page(_ body: String, number: Int = 1, total: Int = 1) -> String {
        """
        Example Sparkasse
        Kontoauszug 1/2026
        GiroOnline 0000000000, DE00 0000 0000 0000 0000 00
        Seite \(number) von \(total)
        Datum Erläuterung Betrag EUR
        \(body)
        Postanschrift: Example bank
        """
    }

    static let body = """
    Kontostand am 31.08.2026, Auszug Nr. 0 100,00
    01.09.2026dig. Karte Apple Pay
    REWE MARKT 123//Example/DE
    2026-08-31T12:00 Debitk.0
    -12,50
    02.09.2026Gutschrift Überw.
    Test employer SALARY
    1.000,00
    03.09.2026Echtzeit-Überweisung
    Own savings account
    -100,00
    30.09.2026Entgeltabrechnung / Wert: 01.10.2026
    Siehe Anlage Nr. 1
    -2,50
    30.09.2026Abrechnung 30.09.2026 / Wert: 01.10.2026
    Siehe Anlage Nr. 2
    0,00
    Kontostand am 30.09.2026 um 20:00 Uhr 985,00
    Der Kontostand berücksichtigt nicht die Wertstellung.
    """

    static func document() throws -> StatementDocument {
        try SparkasseStatementParser().parse(pages: [page(body)], name: "Synthetic statement.pdf")
    }
}
