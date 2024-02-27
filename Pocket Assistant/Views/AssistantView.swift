//
//  AssistantView.swift
//  Pocket Assistant
//
//  Created by Robert Schulz on 25.02.24.
//

import SwiftUI

struct AssistantView: View {
  @ObservedObject var viewModel = AssistantViewModel()
  @State private var newMessage = ""  // State for text input

  var body: some View {
    VStack {
      List(viewModel.messages) { message in
        MessageView(message: message)
      }
        // Input area for new messages
      HStack {
        TextField("Message", text: $newMessage)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(.leading, 10)

        Button("Send") {
          Task {
            if let threadId = viewModel.threadId {
              await viewModel.createMessage(threadId: threadId, content: newMessage)
              newMessage = ""  // Reset input field
              try await viewModel.startAndCheckRun(threadId: threadId)

            } else {
              print("Thread ID not available.")
            }
          }
        }
        .padding(.trailing, 10)
      }.padding()
    }
    .onAppear {
      Task {
        if viewModel.threadId == nil {
          await viewModel.createThread()
        }

      }
    }
  }
}

struct AssistantView_Previews: PreviewProvider {
  static var previews: some View {
    AssistantView(viewModel: AssistantViewModel())
  }
}
