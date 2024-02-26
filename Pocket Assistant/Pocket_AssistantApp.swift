//
//  Pocket_AssistantApp.swift
//  Pocket Assistant
//
//  Created by Robert Schulz on 25.02.24.
//

import SwiftUI

@main
struct Pocket_AssistantApp: App {
    @StateObject var viewModel = AssistantViewModel() // Verwende @StateObject für die App-Lebensdauer

    var body: some Scene {
        WindowGroup {
            AssistantView(viewModel: viewModel) // Übergebe das ViewModel als Parameter
        }
    }
}
