//
//  MessageView.swift
//  Pocket Assistant
//
//  Created by Robert Schulz on 26.02.24.
//

import SwiftUI

import SwiftUI

struct MessageView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.role == "user" {
                userMessageView
                    .frame(minWidth: UIScreen.main.bounds.width * 3/4, alignment: .leading)
            } else {
                Spacer() // Fügt einen flexiblen Platzhalter hinzu, um die Nachricht rechtsbündig zu machen
                assistantMessageView
                    .frame(minWidth: UIScreen.main.bounds.width * 3/4, alignment: .trailing)
            }
        }
    }

    private var userMessageView: some View {
        VStack(alignment: .leading) {
            Text(message.content)
                .frame(minWidth: UIScreen.main.bounds.width * 2/3, alignment: .leading)
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
            
            Text(formattedDateString(from: message.createdAt))
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .padding([.leading, .bottom])
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
    }

    private var assistantMessageView: some View {
        VStack(alignment: .trailing) {
            Text(message.content)
                .frame(minWidth: UIScreen.main.bounds.width * 2/3, alignment: .trailing)
                .padding()
                .foregroundColor(.white)
                .background(Color.green)
                .cornerRadius(10)
            
            Text(formattedDateString(from: message.createdAt))
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .padding([.trailing, .bottom])
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        
    }

    private func formattedDateString(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}
