//
//  ContentView.swift
//  Breeze
//
//  Created by Andrew Jaffe on 3/4/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        EditorView(document: documentManager.currentDocument)
    }
}

#Preview {
    ContentView()
        .environmentObject(DocumentManager())
        .environmentObject(SettingsManager())
}
