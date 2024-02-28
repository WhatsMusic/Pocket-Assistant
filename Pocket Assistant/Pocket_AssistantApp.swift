//
//  Pocket_AssistantApp.swift
//  Pocket Assistant
//
//  Created by Robert Schulz on 25.02.24.
//

import SwiftOpenAI
import SwiftUI

@main
struct Pocket_AssistantApp: App {
  @StateObject var viewModel = AssistantViewModel()  // Use @StateObject for the app lifetime
  var body: some Scene {
    WindowGroup {
      AssistantView(viewModel: viewModel)  // Pass the ViewModel as a parameter

    }
  }
}
