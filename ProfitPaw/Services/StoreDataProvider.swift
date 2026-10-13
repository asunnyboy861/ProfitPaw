import Foundation

protocol StoreDataProvider {
    func fetchSnapshot() async throws -> PnlSnapshot
    var isDemo: Bool { get }
}

struct DemoDataProvider: StoreDataProvider {
    var isDemo: Bool { true }

    func fetchSnapshot() async throws -> PnlSnapshot {
        DemoStore.generate()
    }
}

struct APIDataProvider: StoreDataProvider {
    var endpoint: String
    var isDemo: Bool { false }

    func fetchSnapshot() async throws -> PnlSnapshot {
        guard var comps = URLComponents(string: endpoint) else {
            throw URLError(.badURL)
        }
        comps.path = (comps.path.isEmpty ? "" : comps.path) + "/api/aggregate"
        comps.queryItems = [URLQueryItem(name: "days", value: "90")]
        guard let url = comps.url else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PnlSnapshot.self, from: data)
    }
}

enum StoreDataProviderFactory {
    static func make() -> StoreDataProvider {
        if AppSettings.demoMode {
            return DemoDataProvider()
        }
        let endpoint = AppSettings.serverEndpoint
        guard !endpoint.isEmpty else { return DemoDataProvider() }
        return APIDataProvider(endpoint: endpoint)
    }
}
