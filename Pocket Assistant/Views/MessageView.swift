//
//  MessageView.swift
//  Pocket Assistant
//
//  Created by Robert Schulz on 26.02.24.
//

import SwiftUI

struct MessageView: View {
  var message: Message

  var body: some View {
    VStack(alignment: .leading) {
      Text(message.role.capitalized + ":")
        .font(.headline)
        .foregroundColor(message.role == "user" ? .blue : .green)
      Text(message.formattedContent)  // Use the new calculated property here
        .padding(.leading, 5)
    }
  }
}
