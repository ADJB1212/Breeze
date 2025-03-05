//
//  ExportManager.swift
//  Breeze
//
//  Created by Andrew Jaffe on 3/4/25.
//

import AppKit
import Foundation
import SwiftUI

class ExportManager {
    func exportDocument(_ document: TextDocument, as format: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.allowsOtherFileTypes = true
        panel.title = "Export Document"

        switch format.lowercased() {
        case "markdown", "md":
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "document.md"
        case "txt":
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "document.txt"
        case "html":
            panel.allowedContentTypes = [.html]
            panel.nameFieldStringValue = "document.html"
        case "pdf":
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "document.pdf"
        case "rtf":
            panel.allowedContentTypes = [.rtf]
            panel.nameFieldStringValue = "document.rtf"
        default:
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "document.txt"
        }

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    var data: Data

                    switch format.lowercased() {
                    case "html":
                        data = self.convertToHTML(document.text).data(using: .utf8)!
                    case "pdf":
                        data = self.convertToPDF(document.text)
                    case "rtf":
                        data = self.convertToRTF(document.text)
                    default:
                        data = document.text.data(using: .utf8)!
                    }

                    try data.write(to: url)
                } catch {
                    print("Error exporting document: \(error.localizedDescription)")
                }
            }
        }
    }

    private func convertToHTML(_ markdown: String) -> String {
        // Simple markdown to HTML conversion
        var html =
            "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><style>body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; padding: 20px; max-width: 800px; margin: 0 auto; }</style></head><body>"

        // Basic conversion for demonstration
        let paragraphs = markdown.components(separatedBy: "\n\n")
        for paragraph in paragraphs {
            if paragraph.hasPrefix("# ") {
                let title = paragraph.dropFirst(2)
                html += "<h1>\(title)</h1>"
            } else if paragraph.hasPrefix("## ") {
                let title = paragraph.dropFirst(3)
                html += "<h2>\(title)</h2>"
            } else if paragraph.hasPrefix("### ") {
                let title = paragraph.dropFirst(4)
                html += "<h3>\(title)</h3>"
            } else {
                html += "<p>\(paragraph)</p>"
            }
        }

        html += "</body></html>"
        return html
    }

    private func convertToPDF(_ text: String) -> Data {
        let attributedString = NSAttributedString(string: text)
        let printInfo = NSPrintInfo.shared
        printInfo.paperSize = NSSize(width: 612, height: 792)  // Letter size
        printInfo.leftMargin = 72
        printInfo.rightMargin = 72
        printInfo.topMargin = 72
        printInfo.bottomMargin = 72

        let dataObject = NSMutableData()
        let dataConsumer = CGDataConsumer(data: dataObject as CFMutableData)!

        var mediaBox = CGRect(
            x: 0, y: 0, width: printInfo.paperSize.width, height: printInfo.paperSize.height)

        let context = CGContext(consumer: dataConsumer, mediaBox: &mediaBox, nil)!

        context.beginPage(mediaBox: &mediaBox)

        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let path = CGPath(
            rect: CGRect(
                x: printInfo.leftMargin, y: printInfo.bottomMargin,
                width: printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin,
                height: printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin),
            transform: nil)

        let frame = CTFramesetterCreateFrame(
            framesetter, CFRangeMake(0, attributedString.length), path, nil)
        CTFrameDraw(frame, context)

        context.endPage()

        return dataObject as Data
    }

    private func convertToRTF(_ text: String) -> Data {
        let attributedString = NSAttributedString(string: text)
        return try! attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
    }
}
