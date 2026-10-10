//
//  FinanceStyle.swift
//  FinAI
//
//  Created by Tommy on 07.10.26.
//

import SwiftUI

enum FinanceStyle {
    enum Spacing {
        static let tight: CGFloat = 4
        static let compact: CGFloat = 8
        static let standard: CGFloat = 16
        static let section: CGFloat = 24
        static let spacious: CGFloat = 32
    }

    enum Typography {
        static let amount = Font.largeTitle.weight(.semibold)
        static let heading = Font.title2.weight(.semibold)
        static let label = Font.subheadline
        static let explanation = Font.footnote
    }

    enum Surface {
        static var canvas: Color { FinanceAsset.financeCanvas }
        static var card: Color { FinanceAsset.financeCard }
    }

    enum ColorRole {
        static var text: Color { FinanceAsset.financeTextPrimary }
        static var secondaryText: Color { FinanceAsset.financeTextSecondary }
        static var accent: Color { FinanceAsset.financeAccent }
        static var onAccent: Color { FinanceAsset.financeOnAccent }
        static var accentSoft: Color { FinanceAsset.financeAccentSoft }
        static var border: Color { FinanceAsset.financeBorder }
        static var danger: Color { FinanceAsset.financeDanger }
        static var warning: Color { FinanceAsset.financeWarning }
        static var success: Color { FinanceAsset.financeSuccess }
    }

    static let controlRadius: CGFloat = 12
    static let cardRadius: CGFloat = 20
}
