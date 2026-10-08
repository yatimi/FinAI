//
//  FinanceStyle.swift
//  FinAI
//
//  Created by Tommy on 07.10.26.
//

import SwiftUI

enum FinanceStyle {
    enum Spacing {
        static let compact: CGFloat = 8
        static let standard: CGFloat = 16
        static let section: CGFloat = 24
    }

    enum Typography {
        static let amount = Font.system(.largeTitle, design: .rounded, weight: .semibold)
        static let heading = Font.title2.weight(.semibold)
        static let label = Font.subheadline
        static let explanation = Font.footnote
    }

    enum Surface {
        static let canvas = Color(uiColor: .systemGroupedBackground)
        static let card = Color(uiColor: .secondarySystemGroupedBackground)
    }

    static let cardRadius: CGFloat = 20
}
