//
//  EditorView.swift
//  Breeze
//
//  Created by Andrew Jaffe on 3/4/25.
//

import AVFoundation
import AppKit
import Combine
import Foundation
import MarkdownUI
import SwiftUI

class SpeechManager: NSObject, AVSpeechSynthesizerDelegate, ObservableObject {
    @Published var isSpeaking = false
    @Published var speechRate: Float = 0.5
    private let speechSynthesizer = AVSpeechSynthesizer()
    var currentSpeakingRange: NSRange?
    var editorText: String = ""
    var textView: NSTextView?
    private var testSpeechSynthesizer: AVSpeechSynthesizer?

    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }

    func startSpeaking() {
        guard let textView = self.textView, !editorText.isEmpty else {
            speakDirectly("No text available to speak")
            return
        }

        stopSpeaking()

        // Calculate text range to speak
        let selectedRange = textView.selectedRange()
        var rangeToSpeak: NSRange

        if selectedRange.length > 0 {
            // Use selected text if available
            rangeToSpeak = selectedRange
        } else {
            // Start from cursor position to end of document
            let startPos = selectedRange.location
            rangeToSpeak = NSRange(location: startPos, length: editorText.count - startPos)
        }

        // Ensure range is valid
        if rangeToSpeak.location >= editorText.count {
            rangeToSpeak.location = 0
            rangeToSpeak.length = editorText.count
        }

        if rangeToSpeak.location + rangeToSpeak.length > editorText.count {
            rangeToSpeak.length = editorText.count - rangeToSpeak.location
        }

        // Final safety check
        guard
            rangeToSpeak.location >= 0 && rangeToSpeak.length > 0
                && rangeToSpeak.location + rangeToSpeak.length <= editorText.count
        else {
            speakDirectly("Invalid text selection")
            return
        }

        // Extract text to speak
        let nsString = editorText as NSString
        let textToSpeak = nsString.substring(with: rangeToSpeak)

        guard !textToSpeak.isEmpty else {
            speakDirectly("No text selected")
            return
        }

        // Create utterance
        let utterance = AVSpeechUtterance(string: textToSpeak)
        utterance.rate = speechRate
        utterance.volume = 1.0

        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        // Store the starting range for highlighting
        currentSpeakingRange = rangeToSpeak

        // Start speaking
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.speechSynthesizer.speak(utterance)
            self.isSpeaking = true
        }
    }

    // Simple function to speak text directly without editor involvement
    func speakDirectly(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.volume = 1.0
        utterance.rate = 0.5

        // Create a new synthesizer for direct speech
        testSpeechSynthesizer = AVSpeechSynthesizer()
        testSpeechSynthesizer?.speak(utterance)
    }

    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        testSpeechSynthesizer?.stopSpeaking(at: .immediate)

        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
        }

        // Remove highlighting
        if let textView = self.textView, let currentSpeakingRange = currentSpeakingRange {
            textView.setSelectedRange(NSRange(location: currentSpeakingRange.location, length: 0))
        }
        currentSpeakingRange = nil
    }

    // MARK: - AVSpeechSynthesizerDelegate methods

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = true
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        // Calculate the actual range in the document
        if let currentRange = currentSpeakingRange {
            let updatedRange = NSRange(
                location: currentRange.location + characterRange.location,
                length: characterRange.length)
            DispatchQueue.main.async { [weak self] in
                self?.highlightCurrentSentence(at: updatedRange)
            }
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
        }
    }

    func highlightCurrentSentence(at range: NSRange) {
        guard let textView = self.textView else { return }

        // Highlight the current sentence
        textView.scrollRangeToVisible(range)
        textView.setSelectedRange(range)
    }
}

struct EditorView: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var editorText: String = ""
    @State private var textEditorUndoManager: UndoManager? = nil
    @State private var markdownWidth: CGFloat = 250

    @StateObject private var speechManager = SpeechManager()
    @State private var textView: NSTextView?

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
                        speechManager.editorText = newValue
                    }
                    .background(
                        UndoRedoObserver(undoManager: $textEditorUndoManager, textView: $textView)
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
                        Button(action: {
                            if speechManager.isSpeaking {
                                speechManager.stopSpeaking()
                            } else {
                                // Pass the current document text explicitly
                                speechManager.editorText = editorText
                                speechManager.startSpeaking()
                            }
                        }) {
                            Text(speechManager.isSpeaking ? "Stop Speaking" : "Start Speaking")
                        }

                        Divider()

                        Text("Speech Rate")

                        HStack {
                            Text("Slow")
                            Slider(
                                value: Binding(
                                    get: { speechManager.speechRate },
                                    set: { speechManager.speechRate = $0 }
                                ), in: 0.1...1.0, step: 0.1
                            )
                            .frame(width: 100)
                            .onChange(of: speechManager.speechRate) { _, newValue in
                                if speechManager.isSpeaking {
                                    speechManager.stopSpeaking()
                                    speechManager.startSpeaking()
                                }
                            }
                            Text("Fast")
                        }
                        .padding(.horizontal)
                    } label: {
                        Image(
                            systemName: speechManager.isSpeaking
                                ? "speaker.wave.3.fill" : "speaker.wave.2"
                        )
                        .foregroundColor(speechManager.isSpeaking ? .accentColor : nil)
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
                speechManager.editorText = document.text
            }
            .onChange(of: document.text) { _, newValue in
                if editorText != newValue {
                    editorText = newValue
                    speechManager.editorText = newValue
                }
            }
            .onChange(of: textView) { _, newValue in
                speechManager.textView = newValue
            }
            .onDisappear {
                speechManager.stopSpeaking()
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
    @Binding var textView: NSTextView?
    var textPadding: CGFloat = 10

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window,
                let contentView = window.contentView,
                let foundTextView = findTextView(in: contentView)
            {
                undoManager = foundTextView.undoManager
                textView = foundTextView
                foundTextView.textContainerInset = NSSize(width: textPadding, height: textPadding)
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
