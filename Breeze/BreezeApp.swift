//
//  BreezeApp.swift
//  Breeze
//
//  Created by Andrew Jaffe on 3/4/25.
//

import SwiftUI

@main
struct BreezeApp: App {
    @StateObject private var documentManager = DocumentManager()
    @StateObject private var settingsManager = SettingsManager()

    var body: some Scene {
        DocumentGroup(newDocument: TextDocument()) { file in
            EditorView(document: file.document)
                .environmentObject(documentManager)
                .environmentObject(settingsManager)
        }
        .commands {
            CommandGroup(after: .textEditing) {
                Button("Find and Replace...") {
                    documentManager.showFindReplace = true
                }
                .keyboardShortcut("f", modifiers: [.command])

                Divider()

                Button(
                    documentManager.isMarkdownRendered
                        ? "Hide Markdown Preview" : "Show Markdown Preview"
                ) {
                    documentManager.toggleMarkdownRendering()
                }
                .keyboardShortcut("p", modifiers: [.command])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(settingsManager)
                .environmentObject(documentManager)
        }
    }
}
