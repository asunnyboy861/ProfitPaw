import Foundation

enum TrustCalculator {
    static func coverage(days: [DailyPnl], adCoverage: [String: Double]) -> Double {
        guard !days.isEmpty else { return 0 }
        var spendWeighted = 0.0
        var total = 0.0
        for day in days {
            let daySpend = (day.input.adSpend.meta as NSString).doubleValue
                + (day.input.adSpend.google as NSString).doubleValue
                + (day.input.adSpend.tiktok as NSString).doubleValue
            let dayCoverage = minCoverage(adCoverage)
            spendWeighted += daySpend * dayCoverage
            total += daySpend
        }
        guard total > 0 else { return 100 }
        return spendWeighted / total * 100
    }

    private static func minCoverage(_ adCoverage: [String: Double]) -> Double {
        let values = adCoverage.values
        guard let minV = values.min() else { return 0 }
        return min(100, max(0, minV))
    }
}

struct MetricsAggregator {
    let snapshot: PnlSnapshot

    var today: DailyPnl? { snapshot.days.last }
    var yesterday: DailyPnl? { snapshot.days.count >= 2 ? snapshot.days[snapshot.days.count - 2] : nil }

    func day(on date: Date) -> DailyPnl? {
        let cal = Calendar.current
        return snapshot.days.first { cal.isDate($0.date, inSameDayAs: date) }
    }

    func lastDays(_ n: Int) -> [DailyPnl] {
        Array(snapshot.days.suffix(n))
    }

    var wowDeltaPct: Double {
        guard let today else { return 0 }
        let cal = Calendar.current
        let thisWeek = snapshot.days.filter { cal.isDate($0.date, inSameDayAs: today.date) || ($0.date < today.date && $0.date > cal.date(byAdding: .day, value: -7, to: today.date)!) }
        let lastWeek = snapshot.days.filter { $0.date <= cal.date(byAdding: .day, value: -7, to: today.date)! && $0.date > cal.date(byAdding: .day, value: -14, to: today.date)! }
        let a = thisWeek.reduce(Decimal.zero) { $0 + $1.result.netProfit }
        let b = lastWeek.reduce(Decimal.zero) { $0 + $1.result.netProfit }
        guard b != 0 else { return 0 }
        return NSDecimalNumber(decimal: ((a - b) / b)).doubleValue
    }

    func waterfall(for date: Date) -> [WaterfallStep] {
        guard let d = day(on: date) else { return [] }
        return PnlEngine.waterfall(for: d.input)
    }

    func orders(on date: Date) -> [OrderRecord] {
        let cal = Calendar.current
        return snapshot.orders.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    func productPnl(daysBack: Int) -> [ProductPnl] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let recent = snapshot.orders.filter { $0.date >= cutoff && PnlEngine.decimal($0.refundAmount) < $0.revenueGross }
        var bySku: [String: (units: Int, revenue: Decimal, cogs: Decimal)] = [:]
        for order in recent {
            for line in order.lines {
                var acc = bySku[line.sku] ?? (0, Decimal.zero, Decimal.zero)
                acc.units += line.qty
                acc.revenue += PnlEngine.decimal(line.unitPrice) * Decimal(line.qty)
                acc.cogs += PnlEngine.decimal(line.unitCost) * Decimal(line.qty)
                bySku[line.sku] = acc
            }
        }
        return bySku.map { sku, acc in
            let profit = acc.revenue - acc.cogs
            let roas = acc.revenue == 0 ? Decimal.zero : acc.revenue / max(acc.revenue - acc.cogs, 0.01)
            return ProductPnl(sku: sku, title: title(for: sku), units: acc.units, revenue: acc.revenue, cogs: acc.cogs, profit: profit, breakEvenRoas: roas)
        }.sorted { $0.profit > $1.profit }
    }

    func title(for sku: String) -> String {
        snapshot.orders.compactMap { $0.lines.first { $0.sku == sku } }.first?.title ?? sku
    }

    func campaignPnl(daysBack: Int) -> [CampaignPnl] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        var totals: [String: Decimal] = ["Meta": 0, "Google": 0, "TikTok": 0]
        for day in snapshot.days where day.date >= cutoff {
            totals["Meta", default: 0] += PnlEngine.decimal(day.input.adSpend.meta)
            totals["Google", default: 0] += PnlEngine.decimal(day.input.adSpend.google)
            totals["TikTok", default: 0] += PnlEngine.decimal(day.input.adSpend.tiktok)
        }
        return totals.map { CampaignPnl(platform: $0.key, spend: $0.value) }.sorted { $0.spend > $1.spend }
    }

    var storePOAS: Decimal {
        let ad = snapshot.days.reduce(Decimal.zero) { $0 + $1.input.adSpend.total }
        let profit = snapshot.days.reduce(Decimal.zero) { $0 + $1.result.netProfit }
        guard ad > 0 else { return 0 }
        return profit / ad
    }

    var todayAdSpend: Decimal {
        today.map { $0.input.adSpend.total } ?? 0
    }

    var averageDailyAdSpend: Decimal {
        guard !snapshot.days.isEmpty else { return 0 }
        let total = snapshot.days.reduce(Decimal.zero) { $0 + $1.input.adSpend.total }
        return total / Decimal(snapshot.days.count)
    }

    var breakEvenRoas: Decimal {
        today?.result.breakEvenRoas ?? 0
    }

    func minifiedJson() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let payload = AggregatePayload(
            days: snapshot.days.suffix(30).map { d in
                DayAgg(date: ISO8601DateFormatter().string(from: d.date),
                       revenue: "\(d.result.netRevenue)", profit: "\(d.result.netProfit)",
                       margin: "\(d.result.marginPct)", adSpend: "\(d.input.adSpend.total)")
            },
            topProducts: productPnl(daysBack: 30).prefix(5).map { p in
                ProductAgg(sku: p.sku, title: p.title, units: p.units, profit: "\(p.profit)")
            },
            campaignSpend: campaignPnl(daysBack: 30).map { c in PlatformSpend(platform: c.platform, spend: "\(c.spend)") },
            breakEvenRoas: "\(breakEvenRoas)",
            poas: "\(storePOAS)"
        )
        guard let data = try? encoder.encode(payload) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    struct AggregatePayload: Codable {
        var days: [DayAgg]
        var topProducts: [ProductAgg]
        var campaignSpend: [PlatformSpend]
        var breakEvenRoas: String
        var poas: String
    }
    struct DayAgg: Codable {
        var date: String
        var revenue: String
        var profit: String
        var margin: String
        var adSpend: String
    }
    struct ProductAgg: Codable {
        var sku: String
        var title: String
        var units: Int
        var profit: String
    }
    struct PlatformSpend: Codable {
        var platform: String
        var spend: String
    }
}
