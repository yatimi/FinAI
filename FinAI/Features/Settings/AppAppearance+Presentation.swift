//
//  AppAppearance+Presentation.swift
//  FinAI
//
//  Created by Tommy on 17.11.26.
//

import SwiftUI

extension AppAppearance {
    var title: LocalizedStringResource {
        switch self {
        case .system: .appearanceSystem
        case .light: .appearanceLight
        case .dark: .appearanceDark
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
