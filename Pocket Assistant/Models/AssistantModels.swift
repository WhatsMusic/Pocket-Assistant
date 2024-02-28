//
//  AssistantModels.swift
//  Pocket Assistant
//
//  Created by Robert Schulz on 25.02.24.
//

import Foundation

struct Message: Identifiable, Codable, Comparable {
  var id: UUID
  var threadId: String
  var role: String
  var content: String
  var createdAt: Date

//  // Calculated property that returns the formatted content
//  var formattedContent: String {
//    let dateFormatter = DateFormatter()
//    dateFormatter.dateStyle = .medium
//    dateFormatter.timeStyle = .short
//    let dateString = dateFormatter.string(from: createdAt)
//
//    return "\(content)\n(sent \(dateString))"
//  }

  static func < (lhs: Message, rhs: Message) -> Bool {
    return lhs.createdAt < rhs.createdAt
  }
}

struct MessageParameter: Encodable {
  enum Role: String, Encodable {
    case user = "user"
    case assistant = "assistant"
  }

  let role: Role
  let content: String
}

struct MessageCreationResponse: Identifiable, Codable {
  var id: String
  var object: String
  var createdAt: Int
  var threadId: String
  var role: String
  var content: [Content]
}

struct TextContent: Codable {
  var value: String
  var annotations: [String]?
}

public enum Content: Codable {
  case text(Text)
  case imageFile(ImageFile)

  public struct Text: Codable {
    public let value: String
    // Andere Eigenschaften und Annotationen...
  }

  public struct ImageFile: Codable {
    // Strukturdefinition...
  }
}
// Tool-Struktur, um die Tools im Run zu repräsentieren
struct Tool {
  var type: String
}

struct MessageResponse: Codable {
  let id: String
  let threadId: String
  let role: String
  let content: [MessageContent]
  let createdAt: Double  // oder String, je nachdem, wie das Datum formatiert ist

  enum CodingKeys: String, CodingKey {
    case id
    case threadId = "thread_id"
    case role
    case content
    case createdAt = "created_at"
  }
}

struct MessageContent: Codable {
  let type: String
  let text: String?  // oder ein anderer Typ, je nachdem, was `content` enthält
  let role: String
}

// Antwort-Struktur für das Erstellen eines Runs
struct RunResponse: Codable {
  var id: String?
  var status: String?
  // Weitere Eigenschaften hier einfügen...
}

struct ThreadResponse: Codable {
  let id: String?
  let object: String
  let createdAt: Int
  let metadata: [String: String]

  enum CodingKeys: String, CodingKey {
    case id
    case object
    case createdAt = "created_at"
    case metadata
  }

}
