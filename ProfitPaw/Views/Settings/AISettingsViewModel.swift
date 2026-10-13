import Foundation
import SwiftUI

@MainActor
final class AISettingsViewModel: ObservableObject {
    @Published var providers: [BYOProviderConfig] = []
    @Published var verifyingID: String?

    init() {
        providers = BYOStore.load()
    }

    func persist() {
        BYOStore.save(providers)
    }

    func add(_ preset: BYOProviderConfig.Preset) {
        let config = BYOProviderConfig.new(preset)
        providers.append(config)
        persist()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            KeyStore.deleteProviderKey(ref: providers[index].apiKeyRef)
        }
        providers.remove(atOffsets: offsets)
        persist()
    }

    func saveKey(_ key: String, for config: BYOProviderConfig) {
        KeyStore.saveProviderKey(key, ref: config.apiKeyRef)
    }

    func key(for config: BYOProviderConfig) -> String {
        KeyStore.readProviderKey(ref: config.apiKeyRef) ?? ""
    }

    func verify(_ config: BYOProviderConfig) async {
        verifyingID = config.id
        let result = await BYOClient.verify(config)
        if let index = providers.firstIndex(where: { $0.id == config.id }) {
            switch result {
            case .verified:
                providers[index].status = .verified
            case .badKey, .badURL, .rateLimited, .failed:
                providers[index].status = .error
            }
            persist()
        }
        verifyingID = nil
    }

    func verifyMessage(_ result: BYOClient.VerifyResult) -> String {
        switch result {
        case .verified: return "Connected"
        case .badKey: return "Key rejected (401)"
        case .badURL: return "Endpoint not found (404)"
        case .rateLimited: return "Rate limited (429)"
        case .failed(let message): return message
        }
    }

    func setDefault(_ config: BYOProviderConfig, task: BYOProviderConfig.Task, enabled: Bool) {
        for index in providers.indices {
            if enabled {
                providers[index].isDefaultFor.removeAll { $0 == task }
            }
        }
        if enabled, let index = providers.firstIndex(where: { $0.id == config.id }) {
            providers[index].isDefaultFor.append(task)
        }
        persist()
    }
}
