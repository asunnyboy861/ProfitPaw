import Foundation

enum GLMCloud {
    static let workerURL = URL(string: "https://cramjam-api.calcs.top")!
    static let fallbackWorkerURL = URL(string: "https://cramjam-proxy.iocompile67692.workers.dev")!
    static let appId = "profitpaw"

    static var devKey: String? {
        guard let url = Bundle.main.url(forResource: "GLMProxySecret", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        return lines.first
    }

    static var isConfigured: Bool { devKey != nil }

    static func call(payload: [String: Any]) async throws -> String {
        guard devKey != nil else { throw CloudError.notConfigured }
        return try await post(payload: payload, url: workerURL)
    }

    private static func post(payload: [String: Any], url: URL) async throws -> String {
        var body: [String: Any] = [
            "appId": appId,
            "userId": KeyStore.userId,
            "payload": payload
        ]
        if let key = devKey {
            body["devKey"] = key
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            if status >= 500 && url == workerURL {
                return try await post(payload: payload, url: fallbackWorkerURL)
            }
            throw CloudError.rejected(status)
        }
        let decoded = try JSONDecoder().decode(GLMResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw CloudError.rejected(status)
        }
        return content
    }

    static func extractInvoice(imageBase64: String) async throws -> [InvoiceItem] {
        let content = try await call(payload: [
            "messages": [
                ["role": "system",
                 "content": "Extract supplier invoice items. Return JSON: {\"items\":[{\"sku_guess\":\"\",\"description\":\"\",\"unit_cost\":\"\",\"currency\":\"\",\"qty\":0}]}. If not an invoice return {\"error\":\"not_invoice\"}."],
                ["role": "user", "content": [
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(imageBase64)"]]
                ]]
            ],
            "thinking": ["level": "low"],
            "max_tokens": 8192,
            "temperature": 0.3,
            "response_format": ["type": "json_object"]
        ])
        return try parseInvoice(content)
    }

    static func diagnose(aggJson: String) async throws -> [Recommendation] {
        let content = try await call(payload: [
            "messages": [
                ["role": "system",
                 "content": "You are a DTC profit analyst. Give exactly 3 actionable recommendations, each citing specific numbers (campaign/product/delta%). Return JSON: {\"recommendations\":[{\"title\":\"\",\"why\":\"\",\"evidence\":[],\"expected_impact_pct\":0}]}"],
                ["role": "user", "content": "Weekly aggregate: \(aggJson)"]
            ],
            "thinking": ["level": "high"],
            "max_tokens": 4096,
            "temperature": 0.3,
            "response_format": ["type": "json_object"]
        ])
        return try parseRecommendations(content)
    }

    static func parseInvoice(_ content: String) throws -> [InvoiceItem] {
        guard let data = JSONFragments.firstJSON(from: content)?.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CloudError.rejected(200)
        }
        if obj["error"] as? String == "not_invoice" {
            throw CloudError.rejected(422)
        }
        guard let items = obj["items"] as? [[String: Any]] else {
            throw CloudError.rejected(200)
        }
        return items.compactMap { dict in
            guard let desc = dict["description"] as? String else { return nil }
            return InvoiceItem(
                skuGuess: dict["sku_guess"] as? String ?? "",
                itemDescription: desc,
                unitCost: "\(dict["unit_cost"] as? String ?? dict["unit_cost"].map { "\($0)" } ?? "0")",
                currency: dict["currency"] as? String ?? "USD",
                qty: (dict["qty"] as? NSNumber)?.intValue ?? 1
            )
        }
    }

    static func parseRecommendations(_ content: String) throws -> [Recommendation] {
        guard let data = JSONFragments.firstJSON(from: content)?.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let recs = obj["recommendations"] as? [[String: Any]] else {
            throw CloudError.rejected(200)
        }
        return recs.compactMap { dict in
            guard let title = dict["title"] as? String else { return nil }
            return Recommendation(
                title: title,
                why: dict["why"] as? String ?? "",
                evidence: dict["evidence"] as? [String] ?? [],
                expectedImpactPct: (dict["expected_impact_pct"] as? NSNumber)?.doubleValue ?? 0
            )
        }
    }
}

enum JSONFragments {
    static func firstJSON(from text: String) -> String? {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            let lines = cleaned.components(separatedBy: "\n")
            let inner = lines.dropFirst().prefix(while: { !$0.hasSuffix("```") })
            cleaned = inner.joined(separator: "\n")
        }
        if let start = cleaned.firstIndex(of: "{"), let end = cleaned.lastIndex(of: "}") {
            return String(cleaned[start...end])
        }
        return cleaned
    }
}
