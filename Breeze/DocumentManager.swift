//
//  DocumentManager.swift
//  Breeze
//
//  Created by Andrew Jaffe on 3/4/25.
//

import Combine
import SwiftUI

class DocumentManager: ObservableObject {
    @Published var currentDocument = TextDocument()
    @Published var findText = ""
    @Published var replaceText = ""
    @Published var showFindReplace = false
    @Published var isMarkdownRendered = false

    // Track modification status
    @Published var isDocumentModified = false

    // Auto-save timer
    private var autoSaveTimer: Timer?
    private var lastSaveTime = Date()

    init() {
        setupAutoSave()
    }

    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) {
            [weak self] _ in
            self?.autoSaveDocument()
        }
    }

    func autoSaveDocument() {
        // Implement auto-save logic
        if isDocumentModified {
            // Save document
            isDocumentModified = false
            lastSaveTime = Date()
        }
    }

    func findNext() -> NSRange? {
        guard !findText.isEmpty else { return nil }

        let text = currentDocument.text as NSString
        let range = text.range(
            of: findText, options: .caseInsensitive,
            range: NSRange(location: 0, length: text.length))

        return range.location != NSNotFound ? range : nil
    }

    func replaceAll() {
        guard !findText.isEmpty else { return }

        currentDocument.text = currentDocument.text.replacingOccurrences(
            of: findText, with: replaceText)
        isDocumentModified = true
    }

    func toggleMarkdownRendering() {
        isMarkdownRendered.toggle()
    }
}
