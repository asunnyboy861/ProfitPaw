import Foundation
import SwiftUI

@MainActor
final class AskViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var input = ""
    @Published var isThinking = false
    @Published var progressLine = ""
    @Published var lastSource: AIService.Source?

    let suggestions = [
        "Which product made the most money last month?",
        "Why did profit drop this week?",
        "What's my break-even ROAS?"
    ]

    private var snapshot: PnlSnapshot = .empty

    func loadHistory() {
        messages = ChatMessage.loadHistory()
    }

    func attach(snapshot: PnlSnapshot) {
        self.snapshot = snapshot
    }

    func send(_ raw: String?) async {
        let question = (raw ?? input).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isThinking else { return }
        input = ""
        messages.append(ChatMessage(role: "user", text: question, evidence: [], source: ""))
        saveHistory()
        isThinking = true
        progressLine = ""

        let context = MetricsAggregator(snapshot: snapshot).minifiedJson()
        let wordCount = snapshot.orders.count
        progressLine = "Digging into \(wordCount) orders..."

        let response = await AIService.ask(question, context: context)
        isThinking = false
        progressLine = ""
        if let response {
            messages.append(ChatMessage(role: "assistant", text: response.answer.summary, evidence: response.answer.evidence, source: response.source.rawValue))
            lastSource = response.source
        } else {
            messages.append(ChatMessage(role: "assistant", text: guidanceText, evidence: [], source: ""))
        }
        saveHistory()
    }

    private var guidanceText: String {
        if AIService.appleIntelligenceAvailable {
            return "AI didn't answer that one. Try rephrasing, or add your own API key in Settings for deeper analysis."
        }
        return "Apple Intelligence requires iOS 26+. Please configure a custom API key in Settings to unlock AI answers."
    }

    private func saveHistory() {
        ChatMessage.saveHistory(messages)
    }
}
