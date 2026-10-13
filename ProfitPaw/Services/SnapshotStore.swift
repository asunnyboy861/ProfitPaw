import Foundation
import WidgetKit

struct WidgetSnapshot: Codable {
    var netProfit: String
    var currency: String
    var wowDeltaPct: Double
    var trustCoverage: Double
    var isDemo: Bool
    var generatedAt: Date
    var trend7d: [TrendPoint]

    struct TrendPoint: Codable {
        var day: String
        var profit: String
    }
}

enum SnapshotStore {
    static let appGroupName = "group.com.zzoutuo.ProfitPaw"

    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var snapshotURL: URL {
        documentsURL.appendingPathComponent("pnl_snapshot.json")
    }

    static var widgetSnapshotURL: URL? {
        guard let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName) else {
            return documentsURL.appendingPathComponent("widget_snapshot.json")
        }
        return base.appendingPathComponent("widget_snapshot.json")
    }

    static func save(_ snapshot: PnlSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(snapshot) {
            try? data.write(to: snapshotURL, options: .atomic)
        }
        writeWidgetSnapshot(from: snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func load() -> PnlSnapshot? {
        guard let data = try? Data(contentsOf: snapshotURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(PnlSnapshot.self, from: data)
    }

    static func loadWidgetSnapshot() -> WidgetSnapshot? {
        guard let url = widgetSnapshotURL, let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    private static func writeWidgetSnapshot(from snapshot: PnlSnapshot) {
        guard let last = snapshot.days.last else { return }
        let aggregator = MetricsAggregator(snapshot: snapshot)
        let trend = snapshot.days.suffix(7).map { d in
            WidgetSnapshot.TrendPoint(day: shortDay(d.date), profit: "\(d.result.netProfit)")
        }
        let widgetData = WidgetSnapshot(
            netProfit: "\(last.result.netProfit)",
            currency: snapshot.currency,
            wowDeltaPct: aggregator.wowDeltaPct,
            trustCoverage: snapshot.trust.coveragePct,
            isDemo: snapshot.isDemo,
            generatedAt: Date(),
            trend7d: trend
        )
        guard let url = widgetSnapshotURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(widgetData) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private static func shortDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }
}

struct ChatMessage: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var role: String
    var text: String
    var evidence: [String]
    var source: String

    static func loadHistory() -> [ChatMessage] {
        let url = SnapshotStore.documentsURL.appendingPathComponent("chat_history.json")
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([ChatMessage].self, from: data)) ?? []
    }

    static func saveHistory(_ messages: [ChatMessage]) {
        let url = SnapshotStore.documentsURL.appendingPathComponent("chat_history.json")
        let trimmed = Array(messages.suffix(20))
        if let data = try? JSONEncoder().encode(trimmed) {
            try? data.write(to: url, options: .atomic)
        }
    }
}

struct InvoiceScanResult: Codable, Equatable {
    var date: Date
    var items: [InvoiceItem]

    static func load() -> InvoiceScanResult? {
        let url = SnapshotStore.documentsURL.appendingPathComponent("invoice_scan.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(InvoiceScanResult.self, from: data)
    }

    static func save(_ result: InvoiceScanResult) {
        let url = SnapshotStore.documentsURL.appendingPathComponent("invoice_scan.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(result) {
            try? data.write(to: url, options: .atomic)
        }
    }
}

struct WeeklyCardCache: Codable {
    var weekKey: String
    var recommendations: [Recommendation]
    var source: String

    static func load() -> WeeklyCardCache? {
        let url = SnapshotStore.documentsURL.appendingPathComponent("weekly_card.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WeeklyCardCache.self, from: data)
    }

    static func save(_ cache: WeeklyCardCache) {
        let url = SnapshotStore.documentsURL.appendingPathComponent("weekly_card.json")
        if let data = try? JSONEncoder().encode(cache) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
