import Foundation

struct BYOProviderConfig: Codable, Identifiable, Equatable {
    var id: String
    var preset: Preset
    var displayName: String
    var baseURL: String
    var model: String
    var apiKeyRef: String
    var capabilities: Capabilities
    var status: Status
    var isDefaultFor: [Task]

    enum Preset: String, Codable, CaseIterable, Identifiable {
        case openai, gemini, claude, deepseek, glm, custom
        var id: String { rawValue }

        var defaultBaseURL: String {
            switch self {
            case .openai: return "https://api.openai.com/v1"
            case .gemini: return "https://generativelanguage.googleapis.com/v1beta/openai"
            case .claude: return "https://api.anthropic.com/v1"
            case .deepseek: return "https://api.deepseek.com/v1"
            case .glm: return "https://api.z.ai/api/paas/v4"
            case .custom: return ""
            }
        }

        var defaultModel: String {
            switch self {
            case .openai: return "gpt-4o-mini"
            case .gemini: return "gemini-2.5-flash"
            case .claude: return "claude-sonnet-4-5"
            case .deepseek: return "deepseek-chat"
            case .glm: return "glm-5.3-flash"
            case .custom: return ""
            }
        }

        var vision: Bool {
            switch self {
            case .openai, .gemini, .claude, .glm: return true
            case .deepseek: return false
            case .custom: return true
            }
        }

        var reasoning: Bool { true }

        var label: String {
            switch self {
            case .openai: return "OpenAI"
            case .gemini: return "Gemini"
            case .claude: return "Claude"
            case .deepseek: return "DeepSeek"
            case .glm: return "GLM"
            case .custom: return "Custom"
            }
        }
    }

    struct Capabilities: Codable, Equatable {
        var text: Bool
        var vision: Bool
        var reasoning: Bool
    }

    enum Status: String, Codable {
        case unverified, verified, error
    }

    enum Task: String, Codable, CaseIterable {
        case diagnose, invoice
        var label: String {
            self == .diagnose ? "AI diagnosis" : "Invoice scanning"
        }
    }

    static func new(_ preset: Preset) -> BYOProviderConfig {
        let id = UUID().uuidString
        return BYOProviderConfig(
            id: id,
            preset: preset,
            displayName: preset == .custom ? "Custom Endpoint" : preset.label,
            baseURL: preset.defaultBaseURL,
            model: preset.defaultModel,
            apiKeyRef: "provider.\(id)",
            capabilities: Capabilities(text: true, vision: preset.vision, reasoning: preset.reasoning),
            status: .unverified,
            isDefaultFor: []
        )
    }

    var hasKey: Bool { KeyStore.readProviderKey(ref: apiKeyRef) != nil }
}

enum BYOStore {
    private static let key = "byoProviders"

    static func load() -> [BYOProviderConfig] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([BYOProviderConfig].self, from: data)) ?? []
    }

    static func save(_ providers: [BYOProviderConfig]) {
        if let data = try? JSONEncoder().encode(providers) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func defaultProvider(for task: BYOProviderConfig.Task, in providers: [BYOProviderConfig]) -> BYOProviderConfig? {
        if let explicit = providers.first(where: { $0.isDefaultFor.contains(task) && $0.status == .verified && $0.hasKey }) {
            return explicit
        }
        let eligible = providers.filter { $0.status == .verified && $0.hasKey && capability($0, task: task) }
        return eligible.first
    }

    static func capability(_ p: BYOProviderConfig, task: BYOProviderConfig.Task) -> Bool {
        switch task {
        case .invoice: return p.capabilities.vision
        case .diagnose: return p.capabilities.text
        }
    }
}
