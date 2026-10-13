import Foundation

enum BYOClient {
    enum VerifyResult {
        case verified
        case badKey
        case badURL
        case rateLimited
        case failed(String)
    }

    static func chat(_ config: BYOProviderConfig, system: String, user: String, maxTokens: Int, imageBase64: String? = nil) async throws -> String {
        if config.preset == .claude {
            return try await claudeChat(config, system: system, user: user, maxTokens: maxTokens, imageBase64: imageBase64)
        }
        return try await openAIChat(config, system: system, user: user, maxTokens: maxTokens, imageBase64: imageBase64)
    }

    private static func openAIChat(_ config: BYOProviderConfig, system: String, user: String, maxTokens: Int, imageBase64: String?) async throws -> String {
        guard let url = URL(string: config.baseURL.appending("/chat/completions")) else {
            throw CloudError.rejected(400)
        }
        guard let key = KeyStore.readProviderKey(ref: config.apiKeyRef) else {
            throw CloudError.notConfigured
        }
        var messages: [[String: Any]] = [
            ["role": "system", "content": system]
        ]
        if let b64 = imageBase64 {
            messages.append([
                "role": "user",
                "content": [
                    ["type": "text", "text": user],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(b64)"]]
                ]
            ])
        } else {
            messages.append(["role": "user", "content": user])
        }
        var payload: [String: Any] = [
            "model": config.model,
            "messages": messages,
            "max_tokens": maxTokens
        ]
        if config.preset == .glm {
            payload["thinking"] = ["level": maxTokens > 4096 ? "low" : "low"]
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw CloudError.rejected(500)
        }
        return content
    }

    private static func claudeChat(_ config: BYOProviderConfig, system: String, user: String, maxTokens: Int, imageBase64: String?) async throws -> String {
        guard let url = URL(string: config.baseURL.appending("/messages")) else {
            throw CloudError.rejected(400)
        }
        guard let key = KeyStore.readProviderKey(ref: config.apiKeyRef) else {
            throw CloudError.notConfigured
        }
        var contentBlock: [String: Any]
        if let b64 = imageBase64 {
            contentBlock = [
                "role": "user",
                "content": [
                    ["type": "image", "source": ["type": "base64", "media_type": "image/jpeg", "data": b64]],
                    ["type": "text", "text": user]
                ]
            ]
        } else {
            contentBlock = ["role": "user", "content": user]
        }
        let payload: [String: Any] = [
            "model": config.model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [contentBlock]
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArr = obj["content"] as? [[String: Any]],
              let text = contentArr.first?["text"] as? String else {
            throw CloudError.rejected(500)
        }
        return text
    }

    static func verify(_ config: BYOProviderConfig) async -> VerifyResult {
        do {
            _ = try await chat(config, system: "ping", user: "ping", maxTokens: 8)
            return .verified
        } catch CloudError.notConfigured {
            return .badKey
        } catch let error as URLError where error.code == .cannotFindHost || error.code == .cannotConnectToHost {
            return .badURL
        } catch CloudError.rejected(let code) {
            switch code {
            case 401, 403: return .badKey
            case 404: return .badURL
            case 429: return .rateLimited
            default: return .failed("HTTP \(code)")
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    static func answer(_ config: BYOProviderConfig, question: String, context: String) async throws -> ProfitAnswer {
        let system = "You are a DTC profit analyst answering merchant questions about their Shopify store. Answer using ONLY the provided data snapshot. Return JSON: {\"summary\":\"one-sentence conversational conclusion\",\"evidence\":[\"number-backed facts like 'Cozy Hoodie: $210 profit'\"]}"
        let raw = try await chat(config, system: system, user: "Question: \(question)\n\nData snapshot: \(context)", maxTokens: 2048)
        return try decodeAnswer(raw)
    }

    static func scanInvoice(_ config: BYOProviderConfig, imageBase64: String) async throws -> [InvoiceItem] {
        let system = "Extract supplier invoice items. Return JSON: {\"items\":[{\"sku_guess\":\"\",\"description\":\"\",\"unit_cost\":\"\",\"currency\":\"\",\"qty\":0}]}. If not an invoice return {\"error\":\"not_invoice\"}."
        let raw = try await chat(config, system: system, user: "Extract the item costs from this invoice photo.", maxTokens: 4096, imageBase64: imageBase64)
        return try GLMCloud.parseInvoice(raw)
    }

    static func decodeAnswer(_ raw: String) throws -> ProfitAnswer {
        guard let data = JSONFragments.firstJSON(from: raw)?.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ProfitAnswer(summary: raw.prefix(400).description, evidence: [])
        }
        return ProfitAnswer(
            summary: obj["summary"] as? String ?? raw.prefix(400).description,
            evidence: obj["evidence"] as? [String] ?? []
        )
    }
}
