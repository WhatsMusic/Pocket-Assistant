//
//  AssistantView.swift
//  Pocket Assistant
//
//  Created by Robert Schulz on 25.02.24.
//

import SwiftUI

struct AssistantView: View {
    @ObservedObject var viewModel = AssistantViewModel()
    @State private var newMessage = "" // Zustand für die Texteingabe

   
    
    var body: some View {
        VStack {
            // Anzeige der Nachrichten
            List(viewModel.sortedMessages, id: \.id) { message in
                VStack(alignment: .leading) {
                    Text(message.role.capitalized + ":")
                        .font(.headline)
                        .foregroundColor(message.role == "user" ? .blue : .green)
                    Text(message.content)
                        .padding(.leading, 5)
                }
            }
            
            // Eingabebereich für neue Nachrichten
            HStack {
                TextField("Nachricht", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 10)
                
                Button("Senden") {
                    Task {
                        if let threadId = viewModel.threadId {
                            await viewModel.createMessage(threadId: threadId, content: newMessage)
                                newMessage = "" // Eingabefeld zurücksetzen
                            await viewModel.startAndCheckRun(threadId: threadId)
                        } else {
                            print("Thread ID nicht verfügbar.")
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
