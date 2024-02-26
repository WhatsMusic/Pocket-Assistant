//
//  AssistantModels.swift
//  Pocket Assistant
//
//  Created by Robert Schulz on 25.02.24.
//

import Foundation

// Definition for the messages that are sent to the thread
struct Message: Identifiable, Codable, Comparable {
    var id: UUID
    var threadId: String
    var role: String
    var content: String
    var createdAt: Date
    
    // Implementierung der Comparable-Protokollmethode
        static func < (lhs: Message, rhs: Message) -> Bool {
            return lhs.createdAt < rhs.createdAt
        }
    
}

struct MessagesListResponse: Codable {
    let data: [MessageResponse]
}


// Struktur für die Antwort des Nachrichtenerstellungs-Endpunkts
struct MessageResponse: Identifiable, Codable {
    let id: String
    let object: String
    let createdAt: Int
    let threadId: String?
    let role: String
    let content: [Content]
    let fileIds: [String]?
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id, object, role, content, fileIds, metadata
        case threadId = "thread_id"
        case createdAt = "created_at"
    }

   
    
    init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        object = try container.decode(String.self, forKey: .object)
        createdAt = try container.decode(Int.self, forKey: .createdAt)
        threadId = try container.decodeIfPresent(String.self, forKey: .threadId)
        role = try container.decode(String.self, forKey: .role)
        content = try container.decode([Content].self, forKey: .content)
        fileIds = try container.decodeIfPresent([String].self, forKey: .fileIds)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
       
        
    }
}



struct MessageCreationResponse: Identifiable, Codable {
    var id: String
    var object: String
    var createdAt: Int
    var threadId: String
    var role: String
    var content: [Content]
}

struct Content: Codable {
    var type: String
    var text: TextContent
}

struct TextContent: Codable {
    var value: String
    var annotations: [String]?
}



// Tool-Struktur, um die Tools im Run zu repräsentieren
struct Tool {
    var type: String
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

