//
//  TextDocument.swift
//  Breeze
//
//  Created by Andrew Jaffe on 3/4/25.
//

import Combine
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let markdownText = UTType("com.andrewjaffe.Breeze.markdown") ?? .plainText
}

class TextDocument: FileDocument, ObservableObject {
    @Published var text: String
    
    static var readableContentTypes: [UTType] { [.plainText, .markdownText] }
    
    init(text: String = "") {
        self.text = text
    }
    
    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
