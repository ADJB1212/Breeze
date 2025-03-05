//
//  SettingsView.swift
//  Breeze
//
//  Created by Andrew Jaffe on 3/4/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        TabView {
            appearanceSettings
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            editorSettings
                .tabItem {
                    Label("Editor", systemImage: "doc.text")
                }

            exportSettings
                .tabItem {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
        }
        .padding(20)
        .frame(width: 450, height: 300)
    }

    private var appearanceSettings: some View {
        Form {
            Picker("Theme", selection: $settingsManager.selectedColorSchemePreference) {
                ForEach(SettingsManager.ColorSchemePreference.allCases) { theme in
                    Text(theme.title).tag(theme)
                }
            }

            Picker("Font", selection: $settingsManager.fontName) {
                ForEach(settingsManager.availableFonts, id: \.self) { font in
                    Text(font).tag(font)
                }
            }

            VStack(alignment: .leading) {
                Text("Font Size: \(Int(settingsManager.fontSize))")
                Slider(value: $settingsManager.fontSize, in: 8...36, step: 1)
            }
        }
    }

    private var editorSettings: some View {
        Form {
            Toggle("Enable Spell Check", isOn: $settingsManager.enableSpellCheck)

            Toggle("Enable Auto-Save", isOn: $settingsManager.enableAutoSave)

            if settingsManager.enableAutoSave {
                VStack(alignment: .leading) {
                    Text("Auto-Save Interval: \(Int(settingsManager.autoSaveInterval)) seconds")
                    Slider(value: $settingsManager.autoSaveInterval, in: 10...300, step: 10)
                }
            }
        }
    }

    private var exportSettings: some View {
        Form {
            Picker("Default Export Format", selection: $settingsManager.defaultExportFormat) {
                ForEach(settingsManager.exportFormats, id: \.self) { format in
                    Text(format.uppercased()).tag(format)
                }
            }
        }
    }
}
