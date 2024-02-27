//
//  AssistantViewModel.swift
//  Pocket Assistant
//
//  Created by Robert Schulz on 25.02.24.
//

import Combine
import Foundation
import SwiftOpenAI

class AssistantViewModel: ObservableObject {
  @Published var messages: [Message] = []
  @Published var sortedMessages: [Message] = []
  @Published var threadId: String?

  let session = URLSession.shared
  let baseURL = "https://api.openai.com/v1/threads"
  let assistantId = "asst_eAzf6n0FWUIO3CYiGcjGTehB"
  let apiKey: String
  var service: OpenAIService!

  init() {
    if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
      self.apiKey = apiKey
    } else {
      fatalError("API Key not found")
    }
    self.service = OpenAIServiceFactory.service(apiKey: self.apiKey)
  }

  func createThread() async {
    let parameters = CreateThreadParameters()

    do {
      let thread = try await service.createThread(parameters: parameters)

      DispatchQueue.main.async {
        self.threadId = thread.id
      }
    } catch {
      print("Fehler beim Erstellen des Threads: \(error)")
    }
  }

  // Creates a message in a specific thread
  func createMessage(threadId: String, content: String) async {
    let parameters = SwiftOpenAI.MessageParameter(role: .user, content: content)

    do {
      let messageResponse = try await service.createMessage(
        threadID: threadId, parameters: parameters)
      let newMessage = Message(
        id: UUID(),
        threadId: threadId,
        role: "user",
        content: content,  // Use the content sent
        createdAt: Date(timeIntervalSince1970: TimeInterval(messageResponse.createdAt))
      )
      DispatchQueue.main.async {
        self.messages.append(newMessage)
        self.updateSortedMessages()
      }
    } catch {
      print("Error when creating the message: \(error)")
    }
  }

  func updateSortedMessages() {

    let sorted = messages.sorted { $0.createdAt > $1.createdAt }
    DispatchQueue.main.async {
      self.sortedMessages = sorted
    }
  }

  func createRun(threadId: String, assistantId: String) async throws -> String? {
    let parameters = SwiftOpenAI.RunParameter(assistantID: assistantId)
    do {
      let run = try await service.createRun(threadID: threadId, parameters: parameters)
      print("Create Run: Success")

      return run.id

    } catch {
      throw error
    }
  }

  func startAndCheckRun(threadId: String) async throws {
    guard let runId = try await createRun(threadId: threadId, assistantId: assistantId) else {
      return
    }

    var runCompleted = false
    while !runCompleted {
      do {
        try await Task.sleep(nanoseconds: 2_000_000_000)  // Warte 2 Sekunden
        let runResponse = try await retrieveRun(threadId: threadId, runId: runId)
        if runResponse.self.status == "completed" {

          try await fetchAssistantResponse(threadId: threadId, assistantId: assistantId)

          runCompleted = true

        } else {
          print("Waiting for run completion...")
          runCompleted = false
        }
      } catch {
        print("Error when checking the run status or while waiting: \(error)")
        runCompleted = true  // End the loop in the event of an error
      }
    }
  }

  func retrieveRun(threadId: String, runId: String) async throws -> RunResponse {
    do {
      let runObject = try await service.retrieveRun(threadID: threadId, runID: runId)

      // Convert RunObject to RunResponse
      let runResponse = RunResponse(
        id: runObject.id,
        status: runObject.status
      )

      print("Run Status: \(runObject.status)")
      return runResponse
    } catch {
      print("Error when retrieving the run: \(error)")
      throw error
    }
  }

  // This function should asynchronously retrieve a list of message objects
  func fetchAssistantResponse(threadId: String, assistantId: String) async throws {
    do {
      let messagesResponse = try await service.listMessages(
        threadID: threadId, limit: 1, order: "desc", after: nil, before: nil)

      if let lastMessageResponse = messagesResponse.data.last,
        lastMessageResponse.role == "assistant"
      {
        let contents = lastMessageResponse.content.compactMap { content -> String? in
          switch content {
          case .text(let textContent):
            return textContent.text.value
          default:
            return nil
          }
        }

        let combinedContents = contents.joined(separator: ", ")
        let newMessage = Message(
          id: UUID(),
          threadId: lastMessageResponse.threadID,
          role: "assistant",
          content: combinedContents,
          createdAt: Date(timeIntervalSince1970: TimeInterval(lastMessageResponse.createdAt))
        )

        DispatchQueue.main.async {
          self.messages.append(newMessage)
        }
      }
    } catch {
      print("Error when retrieving the assistance response: \(error)")
    }

  }

  //Verwendung der Assistant API ohne Package

  // Erstellt einen neuen Thread
  //    func createThread() async {
  //        guard let url = URL(string: baseURL) else { return }
  //
  //        var request = URLRequest(url: url)
  //        request.httpMethod = "POST"
  //        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
  //        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
  //        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
  //
  //
  //        do {
  //            let (data, _) = try await URLSession.shared.data(for: request)
  //            print(String(data: data, encoding: .utf8) ?? "Keine Antwort")
  //            let response = try JSONDecoder().decode(ThreadResponse.self, from: data)
  //            DispatchQueue.main.async {
  //                self.threadId = response.id
  //            }
  //        } catch {
  //            print("Fehler beim Erstellen des Threads: \(error)")
  //        }
  //    }

  //    // Funktion, um eine neue Nachricht zu senden
  //    func sendMessage(content: String) async {
  //        guard let url = URL(string: "\(baseURL)/messages") else { return }
  //
  //        var request = URLRequest(url: url)
  //        request.httpMethod = "POST"
  //        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
  //        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
  //        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
  //        request.httpBody = try? JSONEncoder().encode([
  //            "assistant_id": assistantId,
  //            "content": content,
  //            "role": "user"
  //        ])
  //
  //        do {
  //            let (data, _) = try await URLSession.shared.data(for: request)
  //            let messageResponse = try JSONDecoder().decode(MessageResponse.self, from: data)
  //            let threadId = messageResponse.threadId ?? "defaultThreadId" // Verwende einen Standardwert, wenn `threadId` nil ist.
  //            let newMessage = Message(
  //                id: UUID(),
  //                threadId: threadId,
  //                role: messageResponse.role,
  //                content: content,
  //                createdAt: Date()
  //            )
  //            DispatchQueue.main.async {
  //                self.messages.append(newMessage)
  //            }
  //        } catch {
  //            print("Fehler beim Senden der Nachricht: \(error)")
  //        }
  //
  //    }

  //    // Erstellt eine Nachricht in einem bestimmten Thread
  //    func createMessage(threadId: String, content: String) async {
  //        guard let url = URL(string: "\(baseURL)/\(threadId)/messages") else { return }
  //
  //        var request = URLRequest(url: url)
  //        request.httpMethod = "POST"
  //        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
  //        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
  //        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
  //        request.httpBody = try? JSONSerialization.data(withJSONObject: ["role": "user", "content": content])
  //
  //        do {
  //            let (_, _) = try await URLSession.shared.data(for: request)
  //            // Handle success if needed
  //            print("Create Message: Success")
  //        } catch {
  //            print("Fehler beim Erstellen der Nachricht: \(error)")
  //        }
  //    }

  // Erstellt einen Run in einem spezifischen Thread
  //    func createRun(threadId: String, assistantId: String) async -> String? {
  //        guard let url = URL(string: "\(baseURL)/\(threadId)/runs") else { return nil }
  //
  //        var request = URLRequest(url: url)
  //        request.httpMethod = "POST"
  //        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
  //        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
  //        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
  //
  //        var body: [String: Any] = ["assistant_id": assistantId]
  //
  //        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
  //
  //        do {
  //            let (data, _) = try await URLSession.shared.data(for: request)
  //            print("Create Run: Success")
  //            let runResponse = try JSONDecoder().decode(RunResponse.self, from: data)
  //            return runResponse.id
  //        } catch {
  //            print("Fehler beim Erstellen eines Runs: \(error)")
  //            return nil
  //        }
  //    }
  //
  //
  //
  //    func retrieveRun(threadId: String, runId: String) async throws -> RunResponse {
  //        guard let url = URL(string: "\(baseURL)/\(threadId)/runs/\(runId)") else {
  //            throw URLError(.badURL)
  //        }
  //
  //        var request = URLRequest(url: url)
  //        request.httpMethod = "GET"
  //        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
  //        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
  //        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
  //
  //        let (data, response) = try await URLSession.shared.data(for: request)
  //        if let httpResponse = response as? HTTPURLResponse {
  //            print("HTTP Status Code: \(httpResponse.statusCode)")
  //        }
  //
  //        let runResponse = try JSONDecoder().decode(RunResponse.self, from: data)
  //        print("Aktueller Run-Status: \(runResponse.status ?? "kein Status")")
  //
  //        return runResponse
  //    }
  //
  //
  //    func fetchAssistantResponse(threadId: String) async {
  //        guard let url = URL(string: "\(baseURL)/\(threadId)/messages") else { return }
  //
  //        var request = URLRequest(url: url)
  //        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
  //        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
  //        do {
  //            let (data, _) = try await URLSession.shared.data(for: request)
  //            let response = try JSONDecoder().decode(MessagesListResponse.self, from: data)
  //
  //            let messages = response.data.map { messageResponse -> Message in
  //                // Hier verarbeitest du fileIds nur, wenn es vorhanden ist.
  //                let fileIdsString = messageResponse.fileIds?.joined(separator: ", ") ?? "Keine Dateien"
  //
  //                // Hier nimmst du an, dass du irgendwie die fileIdsString in deine Nachricht integrieren möchtest.
  //                let contentWithFileIds = "\(messageResponse.content.map { $0.text.value }.joined(separator: ", ")) \nDateien: \(fileIdsString)"
  //
  //                return Message(id: UUID(), threadId: messageResponse.threadId ?? "defaultThreadID", role: messageResponse.role, content: contentWithFileIds, createdAt: Date())
  //            }
  //
  //            DispatchQueue.main.async {
  //                self.messages.append(contentsOf: messages)
  //            }
  //        } catch {
  //            print("Fehler beim Abrufen der Assistenzantwort: \(error)")
  //        }
  //    }

  //    func fetchAssistantResponse(threadId: String) async {
  //        guard let url = URL(string: "\(baseURL)/\(threadId)/messages") else { return }
  //
  //        var request = URLRequest(url: url)
  //        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
  //        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
  //
  //        do {
  //            let (data, _) = try await URLSession.shared.data(for: request)
  //            let response = try JSONDecoder().decode(MessagesListResponse.self, from: data)
  //
  //            let messages = response.data.map { messageResponse -> Message in
  //                // Hier verarbeitest du fileIds nur, wenn es vorhanden ist.
  //                let fileIdsString = messageResponse.fileIds?.joined(separator: ", ") ?? "Keine Dateien"
  //
  //                // Hier nimmst du an, dass du irgendwie die fileIdsString in deine Nachricht integrieren möchtest.
  //                let contentWithFileIds = "\(messageResponse.content.map { $0.text.value }.joined(separator: ", ")) \nDateien: \(fileIdsString)"
  //
  //                return Message(id: UUID(), threadId: messageResponse.threadId ?? "defaultThreadID", role: messageResponse.role, content: contentWithFileIds, createdAt: Date())
  //            }
  //
  //            DispatchQueue.main.async {
  //                self.messages.append(contentsOf: messages)
  //            }
  //        } catch {
  //            print("Fehler beim Abrufen der Assistenzantwort: \(error)")
  //        }
  //    }

}
