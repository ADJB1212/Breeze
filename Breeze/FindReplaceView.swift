//
//  FindReplaceView.swift
//  Breeze
//
//  Created by Andrew Jaffe on 3/4/25.
//

import SwiftUI

struct FindReplaceView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Find and Replace")
                    .font(.headline)
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Find:")
                TextField("Text to find", text: $documentManager.findText)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Replace with:")
                TextField("Replacement text", text: $documentManager.replaceText)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Find Next") {
                    _ = documentManager.findNext()
                }
                .disabled(documentManager.findText.isEmpty)

                Button("Replace All") {
                    documentManager.replaceAll()
                    dismiss()
                }
                .disabled(documentManager.findText.isEmpty)

                Spacer()

                Button("Done") {
                    dismiss()
                }
            }
        }
        .padding()
        .frame(width: 400)
    }
}
