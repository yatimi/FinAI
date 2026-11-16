//
//  FinanceButtonStyle.swift
//  FinAI
//
//  Created by Tommy on 10.10.26.
//

import SwiftUI

struct FinanceButtonStyle: ButtonStyle {
    enum Emphasis {
        case primary
        case secondary
    }

    var emphasis: Emphasis = .primary
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, FinanceStyle.Spacing.standard)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .foregroundStyle(emphasis == .primary
                             ? FinanceStyle.ColorRole.onAccent : FinanceStyle.ColorRole.accent)
            .background(emphasis == .primary
                        ? FinanceStyle.ColorRole.accent : FinanceStyle.ColorRole.accentSoft,
                        in: .rect(cornerRadius: FinanceStyle.controlRadius))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.5)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
