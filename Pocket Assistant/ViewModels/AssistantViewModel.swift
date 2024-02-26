//
//  AssistantViewModel.swift
//  Pocket Assistant
//
//  Created by Robert Schulz on 25.02.24.
//

import Foundation
import Combine


class AssistantViewModel: ObservableObject {
    @Published var messages: [Message] = [] // Geändert zu einer einfachen String-Liste für die Demonstration
    @Published var threadId: String?
    
    let session = URLSession.shared
    let baseURL = "https://api.openai.com/v1/threads" // Basis-URL der API (angepasst für dein Projekt)
    let assistantId = "asst_eAzf6n0FWUIO3CYiGcjGTehB" // ID des Assistenten
    let apiKey = "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" // Dein API-Schlüssel

    var sortedMessages: [Message] {
        messages.sorted { $0.createdAt > $1.createdAt }
    }
    
    
    // Erstellt einen neuen Thread
    func createThread() async {
        guard let url = URL(string: baseURL) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")


        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            print(String(data: data, encoding: .utf8) ?? "Keine Antwort") 
            let response = try JSONDecoder().decode(ThreadResponse.self, from: data)
            DispatchQueue.main.async {
                self.threadId = response.id
            }
        } catch {
            print("Fehler beim Erstellen des Threads: \(error)")
        }
    }


        
    
    
    // Funktion, um eine neue Nachricht zu senden
    func sendMessage(content: String) async {
        guard let url = URL(string: "\(baseURL)/messages") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
        request.httpBody = try? JSONEncoder().encode([
            "assistant_id": assistantId,
            "content": content,
            "role": "user"
        ])
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let messageResponse = try JSONDecoder().decode(MessageResponse.self, from: data)
            let threadId = messageResponse.threadId ?? "defaultThreadId" // Verwende einen Standardwert, wenn `threadId` nil ist.
            let newMessage = Message(
                id: UUID(),
                threadId: threadId,
                role: messageResponse.role,
                content: content,
                createdAt: Date()
            )
            DispatchQueue.main.async {
                self.messages.append(newMessage)
            }
        } catch {
            print("Fehler beim Senden der Nachricht: \(error)")
        }

    }

    
    
    // Erstellt eine Nachricht in einem bestimmten Thread
    func createMessage(threadId: String, content: String) async {
        guard let url = URL(string: "\(baseURL)/\(threadId)/messages") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["role": "user", "content": content])
        
        do {
            let (_, _) = try await URLSession.shared.data(for: request)
            // Handle success if needed
            print("Create Message: Success")
        } catch {
            print("Fehler beim Erstellen der Nachricht: \(error)")
        }
    }


    
    // Erstellt einen Run in einem spezifischen Thread
    func createRun(threadId: String, assistantId: String, model: String? = nil, instructions: String? = nil) async -> String? {
        guard let url = URL(string: "\(baseURL)/\(threadId)/runs") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
        
        var body: [String: Any] = ["assistant_id": assistantId]
        if let model = model {
            body["model"] = model
        }
        if let instructions = instructions {
            body["instructions"] = instructions
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            print("Create Run: Success")
            let runResponse = try JSONDecoder().decode(RunResponse.self, from: data)
            return runResponse.id
        } catch {
            print("Fehler beim Erstellen eines Runs: \(error)")
            return nil
        }
    }
    
    func startAndCheckRun(threadId: String) async {
        guard let runId = await createRun(threadId: threadId, assistantId: assistantId) else { return }
        
        var runCompleted = false
        while !runCompleted {
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000) // Warte 2 Sekunden
                let runResponse = try await retrieveRun(threadId: threadId, runId: runId)
                if runResponse.self.status == "completed" {
                    runCompleted = true
                    await fetchAssistantResponse(threadId: threadId)
                } else {
                    print("Warten auf Run-Abschluss...")
                    runCompleted = false
                }
            } catch {
                print("Fehler beim Überprüfen des Run-Status oder beim Warten: \(error)")
                runCompleted = true // Beende die Schleife im Fehlerfall
            }
        }
    }


    
    func retrieveRun(threadId: String, runId: String) async throws -> RunResponse {
        guard let url = URL(string: "\(baseURL)/\(threadId)/runs/\(runId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
        }
       
        let runResponse = try JSONDecoder().decode(RunResponse.self, from: data)
        print("Aktueller Run-Status: \(runResponse.status ?? "kein Status")")

        return runResponse
    }

   
    func fetchAssistantResponse(threadId: String) async {
        guard let url = URL(string: "\(baseURL)/\(threadId)/messages") else { return }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(MessagesListResponse.self, from: data)
            
            let messages = response.data.map { messageResponse -> Message in
                // Hier verarbeitest du fileIds nur, wenn es vorhanden ist.
                let fileIdsString = messageResponse.fileIds?.joined(separator: ", ") ?? "Keine Dateien"
                
                // Hier nimmst du an, dass du irgendwie die fileIdsString in deine Nachricht integrieren möchtest.
                let contentWithFileIds = "\(messageResponse.content.map { $0.text.value }.joined(separator: ", ")) \nDateien: \(fileIdsString)"
                
                return Message(id: UUID(), threadId: messageResponse.threadId ?? "defaultThreadID", role: messageResponse.role, content: contentWithFileIds, createdAt: Date())
            }
            
            DispatchQueue.main.async {
                self.messages.append(contentsOf: messages)
            }
        } catch {
            print("Fehler beim Abrufen der Assistenzantwort: \(error)")
        }
    }




}
