import WidgetKit
import SwiftUI

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

enum WidgetStore {
    static let appGroupName = "group.com.zzoutuo.ProfitPaw"
    static let brandOrange = Color(red: 0.976, green: 0.451, blue: 0.086)

    static func load() -> WidgetSnapshot? {
        let url: URL?
        if let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName) {
            url = base.appendingPathComponent("widget_snapshot.json")
        } else {
            url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("widget_snapshot.json")
        }
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    static func profit(from raw: String) -> Decimal {
        Decimal(string: raw.replacingOccurrences(of: ",", with: "")) ?? 0
    }
}

struct ProfitEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct ProfitProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProfitEntry {
        ProfitEntry(date: Date(), snapshot: sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (ProfitEntry) -> Void) {
        completion(ProfitEntry(date: Date(), snapshot: WidgetStore.load() ?? sample))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProfitEntry>) -> Void) {
        let entry = ProfitEntry(date: Date(), snapshot: WidgetStore.load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private var sample: WidgetSnapshot {
        WidgetSnapshot(
            netProfit: "1240.00", currency: "USD", wowDeltaPct: 0.18, trustCoverage: 98, isDemo: true, generatedAt: Date(),
            trend7d: [
                WidgetSnapshot.TrendPoint(day: "Mon", profit: "980"),
                WidgetSnapshot.TrendPoint(day: "Tue", profit: "1120"),
                WidgetSnapshot.TrendPoint(day: "Wed", profit: "1340"),
                WidgetSnapshot.TrendPoint(day: "Thu", profit: "1020"),
                WidgetSnapshot.TrendPoint(day: "Fri", profit: "1490"),
                WidgetSnapshot.TrendPoint(day: "Sat", profit: "1610"),
                WidgetSnapshot.TrendPoint(day: "Sun", profit: "1240")
            ]
        )
    }
}

struct ProfitWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ProfitEntry

    var body: some View {
        content
            .widgetBackground(Color(uiColor: .systemBackground))
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = entry.snapshot {
            let profit = WidgetStore.profit(from: snapshot.netProfit)
            switch family {
            case .accessoryCircular:
                gaugeView(profit)
            case .accessoryRectangular:
                rectangularView(profit, snapshot: snapshot)
            case .systemMedium:
                mediumView(profit, snapshot: snapshot)
            default:
                smallView(profit, snapshot: snapshot)
            }
        } else {
            VStack(spacing: 6) {
                Image(systemName: "pawprint.fill")
                    .font(.title3)
                    .foregroundStyle(WidgetStore.brandOrange)
                Text("Open ProfitPaw to load your profit")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    private func gaugeView(_ profit: Decimal) -> some View {
        Gauge(value: min(max(CGFloat(NSDecimalNumber(decimal: profit).doubleValue / 2000), 0), 1), in: 0...1) {
            Image(systemName: "pawprint.fill")
        } currentValueLabel: {
            Text(profit, format: .currency(code: entry.snapshot?.currency ?? "USD").presentation(.narrow))
                .font(.caption2)
        }
        .gaugeStyle(.accessoryCircular)
    }

    private func rectangularView(_ profit: Decimal, snapshot: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(WidgetStore.brandOrange)
                    .font(.caption2)
                Text("Real Profit").font(.caption2.weight(.semibold))
            }
            Text(profit, format: .currency(code: snapshot.currency))
                .font(.headline)
                .minimumScaleFactor(0.7)
            Text(deltaText(snapshot))
                .font(.caption2)
                .foregroundStyle(snapshot.wowDeltaPct >= 0 ? .green : .red)
        }
    }

    private func smallView(_ profit: Decimal, snapshot: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(WidgetStore.brandOrange)
                Text("Today's Real Profit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(profit, format: .currency(code: snapshot.currency))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            HStack(spacing: 6) {
                Text(deltaText(snapshot))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(snapshot.wowDeltaPct >= 0 ? .green : .red)
                Spacer()
                Text(String(format: "%.0f%%", snapshot.trustCoverage))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(2)
    }

    private func mediumView(_ profit: Decimal, snapshot: WidgetSnapshot) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(WidgetStore.brandOrange)
                    Text("Today's Real Profit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(profit, format: .currency(code: snapshot.currency))
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(deltaText(snapshot))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(snapshot.wowDeltaPct >= 0 ? .green : .red)
                if snapshot.isDemo {
                    Text("Demo data")
                        .font(.caption2)
                        .foregroundStyle(WidgetStore.brandOrange)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                ForEach(Array(snapshot.trend7d.suffix(5).enumerated()), id: \.offset) { _, point in
                    HStack(spacing: 6) {
                        Text(point.day).font(.caption2).foregroundStyle(.secondary)
                        Text(WidgetStore.profit(from: point.profit), format: .currency(code: snapshot.currency).presentation(.narrow))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(WidgetStore.profit(from: point.profit) >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding(2)
    }

    private func deltaText(_ snapshot: WidgetSnapshot) -> String {
        String(format: "%@%.0f%% vs last week", snapshot.wowDeltaPct >= 0 ? "▲ " : "▼ ", abs(snapshot.wowDeltaPct) * 100)
    }
}

extension View {
    @ViewBuilder
    func widgetBackground(_ fill: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { fill }
        } else {
            background(fill)
        }
    }
}

struct ProfitPawWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ProfitPawWidget", provider: ProfitProvider()) { entry in
            ProfitWidgetView(entry: entry)
        }
        .configurationDisplayName("Real Profit")
        .description("Today's true net profit with week-over-week change.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct ProfitPawWidgetBundle: WidgetBundle {
    var body: some Widget {
        ProfitPawWidget()
    }
}
