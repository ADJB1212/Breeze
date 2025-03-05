//
//  EditorView.swift
//  Breeze
//
//  Created by Andrew Jaffe on 3/4/25.
//

import Combine
import SwiftUI

struct EditorView: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var editorText: String = ""
    @State private var textEditorUndoManager: UndoManager? = nil

    var body: some View {
        HSplitView {
            TextEditor(text: $editorText)
                .font(.custom(settingsManager.fontName, size: settingsManager.fontSize))
                .disableAutocorrection(!settingsManager.enableSpellCheck)
                .padding()
                .onChange(of: editorText) { _, newValue in
                    document.text = newValue
                    documentManager.isDocumentModified = true
                }
                .background(
                    UndoRedoObserver(undoManager: $textEditorUndoManager)
                )
                .preferredColorScheme(settingsManager.selectedColorSchemePreference.colorScheme)

            if documentManager.isMarkdownRendered {
                ScrollView {
                    Text(LocalizedStringKey(editorText))
                        .font(.custom(settingsManager.fontName, size: settingsManager.fontSize))
                        .textSelection(.enabled)
                        .padding()
                }
                .frame(minWidth: 300)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: {
                    textEditorUndoManager?.undo()
                }) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!(textEditorUndoManager?.canUndo ?? false))

                Button(action: {
                    textEditorUndoManager?.redo()
                }) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(!(textEditorUndoManager?.canRedo ?? false))

                Button(action: {
                    documentManager.showFindReplace.toggle()
                }) {
                    Image(systemName: "magnifyingglass")
                }

                Button(action: {
                    documentManager.toggleMarkdownRendering()
                }) {
                    Image(
                        systemName: documentManager.isMarkdownRendered
                            ? "doc.plaintext" : "doc.richtext")
                }

                Menu {
                    let exportManager = ExportManager()
                    ForEach(settingsManager.exportFormats, id: \.self) { format in
                        Button(format.uppercased()) {
                            exportManager.exportDocument(document, as: format)
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $documentManager.showFindReplace) {
            FindReplaceView()
                .environmentObject(documentManager)
        }
        .onAppear {
            editorText = document.text
        }
        .onChange(of: document.text) { _, newValue in
            if editorText != newValue {
                editorText = newValue
            }
        }
    }
}

// This helper struct accesses the NSTextView's UndoManager
struct UndoRedoObserver: NSViewRepresentable {
    @Binding var undoManager: UndoManager?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            // Try to find the NSTextView in the view hierarchy
            if let window = nsView.window,
                let contentView = window.contentView,
                let textView = findTextView(in: contentView)
            {
                undoManager = textView.undoManager
            }
        }
    }

    private func findTextView(in view: NSView) -> NSTextView? {
        if let textView = view as? NSTextView {
            return textView
        }

        for subview in view.subviews {
            if let textView = findTextView(in: subview) {
                return textView
            }
        }

        return nil
    }
}

#Preview {
    EditorView(document: TextDocument(text: "# Hello Breeze\n\nThis is a markdown editor."))
        .environmentObject(DocumentManager())
        .environmentObject(SettingsManager())
}
