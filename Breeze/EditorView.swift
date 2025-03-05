//
//  EditorView.swift
//  Breeze
//
//  Created by Andrew Jaffe on 3/4/25.
//

import AppKit
import Combine
import Foundation
import MarkdownUI
import SwiftUI

struct EditorView: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State private var editorText: String = ""
    @State private var textEditorUndoManager: UndoManager? = nil
    // The width for the markdown preview pane
    @State private var markdownWidth: CGFloat = 250
    
    var body: some View {
        GeometryReader { geo in
            HSplitView {
                TextEditor(text: $editorText)
                    .font(.custom(settingsManager.fontName, size: settingsManager.fontSize))
                    .disableAutocorrection(!settingsManager.enableSpellCheck)
                    .padding(.init(top: 5, leading: 5, bottom: 5, trailing: 0))
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
                        Markdown(editorText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding()
                        
                        
                    }
                    .frame(minWidth: geo.size.width / 4, maxWidth: 2 * geo.size.width / 3)
                    
                    
                }
                
            }
            .background(
                WindowAccessor { window in
                    if let window = window {
                        window.setContentSize(NSSize(width: 900, height: 800))
                    }
                }
            )
            
            .toolbar {
                ToolbarItemGroup {
                    Button(action: { textEditorUndoManager?.undo() }) {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(!(textEditorUndoManager?.canUndo ?? false))
                    
                    Button(action: { textEditorUndoManager?.redo() }) {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    .disabled(!(textEditorUndoManager?.canRedo ?? false))
                    
                    Button(action: { documentManager.showFindReplace.toggle() }) {
                        Image(systemName: "magnifyingglass")
                    }
                    
                    Button(action: { documentManager.toggleMarkdownRendering() }) {
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
                FindReplaceView().environmentObject(documentManager)
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
}

// Helper for accessing the window (macOS)
struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let nsView = NSView()
        DispatchQueue.main.async {
            self.callback(nsView.window)
        }
        return nsView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// Helper to get the NSTextView's UndoManager
struct UndoRedoObserver: NSViewRepresentable {
    @Binding var undoManager: UndoManager?
    var textPadding: CGFloat = 10
    
    func makeNSView(context: Context) -> NSView { NSView() }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window,
               let contentView = window.contentView,
               let textView = findTextView(in: contentView)
            {
                undoManager = textView.undoManager
                textView.textContainerInset = NSSize(width: textPadding, height: textPadding)
            }
        }
    }
    
    private func findTextView(in view: NSView) -> NSTextView? {
        if let textView = view as? NSTextView { return textView }
        for subview in view.subviews {
            if let found = findTextView(in: subview) { return found }
        }
        return nil
    }
}

#Preview {
    EditorView(
        document: TextDocument(
            text:
                "# Hello Breeze\n\nThis is a markdown editor.\n\nAnother paragraph here."
        )
    )
    .environmentObject(DocumentManager())
    .environmentObject(SettingsManager())
}

extension View {
    func customCursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
