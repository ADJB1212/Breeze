//
//  SettingsManager.swift
//  Breeze
//
//  Created by Andrew Jaffe on 3/4/25.
//

import Combine
import SwiftUI

class SettingsManager: ObservableObject {
    enum ColorSchemePreference: String, CaseIterable, Identifiable {
        case system, light, dark
        
        var id: String { self.rawValue }
        
        var title: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
    
    @AppStorage("colorSchemePreference") var colorSchemePreference: String = ColorSchemePreference
        .system.rawValue
    @AppStorage("fontSize") var fontSize: Double = 14.0
    @AppStorage("fontName") var fontName: String = "SF Pro"
    @AppStorage("enableSpellCheck") var enableSpellCheck: Bool = true
    @AppStorage("enableAutoSave") var enableAutoSave: Bool = true
    @AppStorage("autoSaveInterval") var autoSaveInterval: Double = 30.0
    @AppStorage("defaultExportFormat") var defaultExportFormat: String = "markdown"
    
    var selectedColorSchemePreference: ColorSchemePreference {
        get {
            return ColorSchemePreference(rawValue: colorSchemePreference) ?? .system
        }
        set {
            colorSchemePreference = newValue.rawValue
        }
    }
    
    var availableFonts: [String] {
        return ["SF Pro", "Helvetica", "Menlo", "Times New Roman", "Arial", "Courier"]
    }
    
    var exportFormats: [String] {
        return ["markdown", "txt", "rtf", "html", "pdf"]
    }
}
