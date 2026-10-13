import Foundation

enum DemoStore {
    struct ProductSpec {
        let sku: String
        let title: String
        let price: Decimal
        let costRatio: Double
    }

    static let products: [ProductSpec] = [
        ProductSpec(sku: "COZY-HOODIE", title: "Cozy Hoodie", price: 64, costRatio: 0.38),
        ProductSpec(sku: "TRAVEL-MUG", title: "Travel Mug 2.0", price: 29, costRatio: 0.34),
        ProductSpec(sku: "DOGBANDANA", title: "Dog Bandana Set", price: 19, costRatio: 0.28),
        ProductSpec(sku: "CANDLE-SAGE", title: "Sage Candle", price: 24, costRatio: 0.30),
        ProductSpec(sku: "TOTE-CANVAS", title: "Canvas Tote", price: 34, costRatio: 0.32),
        ProductSpec(sku: "SOCKS-WOOL", title: "Merino Wool Socks", price: 22, costRatio: 0.36),
        ProductSpec(sku: "PHONE-STAND", title: "Aluminum Phone Stand", price: 27, costRatio: 0.40),
        ProductSpec(sku: "JOURNAL-A5", title: "A5 Dot Journal", price: 21, costRatio: 0.29),
        ProductSpec(sku: "TEATOWEL", title: "Linen Tea Towel Pair", price: 26, costRatio: 0.31),
        ProductSpec(sku: "PLANTER-MIN", title: "Mini Planter Trio", price: 39, costRatio: 0.42),
        ProductSpec(sku: "BEANIE-KNIT", title: "Knit Beanie", price: 32, costRatio: 0.37),
        ProductSpec(sku: "STICKER-PACK", title: "Sticker Pack (12)", price: 12, costRatio: 0.20)
    ]

    static func generate(endDate: Date = Date(), days: Int = 90) -> PnlSnapshot {
        var rng = SeededRandom(seed: 0x504157)
        let cal = Calendar.current
        let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -(days - 1), to: endDate) ?? endDate)

        var orders: [OrderRecord] = []
        var daily: [DailyPnl] = []
        var coverageSeries: [String: [Double]] = ["meta": [], "google": [], "tiktok": []]

        for offset in 0..<days {
            let day = cal.date(byAdding: .day, value: offset, to: start) ?? start
            let weekday = cal.component(.weekday, from: day)
            let weekendBoost = (weekday == 1 || weekday == 7) ? 1.35 : 1.0
            let growth = 1.0 + Double(offset) * 0.004
            let orderCount = max(6, Int((14.0 + rng.double() * 14.0) * weekendBoost * growth))

            var dayRevenue = Decimal.zero
            var dayDiscounts = Decimal.zero
            var dayCogs = Decimal.zero
            var dayShipping = Decimal.zero
            var dayFees = Decimal.zero
            var dayRefunds = Decimal.zero
            var dayRefundsCogs = Decimal.zero

            for n in 0..<orderCount {
                let minute = rng.int(in: 0...(23 * 60))
                let orderDate = cal.date(byAdding: .minute, value: minute, to: day) ?? day
                let itemCount = rng.double() < 0.28 ? 2 : 1
                var lines: [LineItem] = []
                for _ in 0..<itemCount {
                    let p = products[rng.int(in: 0...(products.count - 1))]
                    let qty = rng.double() < 0.12 ? 2 : 1
                    let unitCost = (p.price * Decimal(p.costRatio)).rounded(2)
                    lines.append(LineItem(sku: p.sku, title: p.title, qty: qty,
                                          unitPrice: "\(p.price)", unitCost: "\(unitCost)"))
                }
                let discountCode = rng.double() < 0.18
                let gross = lines.reduce(Decimal.zero) { $0 + PnlEngine.decimal($1.unitPrice) * Decimal($1.qty) }
                let discount = discountCode ? (gross * Decimal(string: "0.10")!).rounded(2) : Decimal.zero
                let shippingLabel = (Decimal(string: "5.5")! + Decimal(rng.double() * 4)).rounded(2)
                let payment = gross - discount
                let fee = (payment * Decimal(string: "0.029")! + Decimal(string: "0.30")!).rounded(2)

                let refundRoll = rng.double()
                var refundAmount = Decimal.zero
                var refundCogs = Decimal.zero
                if refundRoll < 0.055 && payment > 0 {
                    refundAmount = payment.rounded(2)
                    refundCogs = lines.reduce(Decimal.zero) { $0 + PnlEngine.decimal($1.unitCost) * Decimal($1.qty) }.rounded(2)
                } else if refundRoll < 0.085 && payment > 0 {
                    refundAmount = (payment * Decimal(string: "0.5")!).rounded(2)
                    refundCogs = (lines.reduce(Decimal.zero) { $0 + PnlEngine.decimal($1.unitCost) * Decimal($1.qty) } * Decimal(string: "0.5")!).rounded(2)
                }

                let order = OrderRecord(
                    id: "demo-\(offset)-\(n)",
                    date: orderDate,
                    number: "#\(10240 + offset * 100 + n)",
                    lines: lines,
                    discount: "\(discount)",
                    refundAmount: "\(refundAmount)",
                    refundedCogs: "\(refundCogs)",
                    shippingLabel: "\(shippingLabel)",
                    paymentFee: "\(fee)"
                )
                orders.append(order)

                dayRevenue += gross
                dayDiscounts += discount
                dayCogs += lines.reduce(Decimal.zero) { $0 + PnlEngine.decimal($1.unitCost) * Decimal($1.qty) }
                dayShipping += shippingLabel
                dayFees += fee
                dayRefunds += refundAmount
                dayRefundsCogs += refundCogs
            }

            let metaSpend = (95 + rng.double() * 85) * weekendBoost
            let googleSpend = (65 + rng.double() * 70) * weekendBoost
            let tiktokSpend = 18 + rng.double() * 55
            let adSpend = AdSpend(meta: Decimal(metaSpend).rounded(2).description,
                                  google: Decimal(googleSpend).rounded(2).description,
                                  tiktok: Decimal(tiktokSpend).rounded(2).description)

            let customCosts = Decimal(string: "8.00")!

            let input = DailyPnlInput(
                revenue: dayRevenue.rounded(2).description,
                discounts: dayDiscounts.rounded(2).description,
                refunds: dayRefunds.rounded(2).description,
                refundsCogs: dayRefundsCogs.rounded(2).description,
                cogs: dayCogs.rounded(2).description,
                shipping: dayShipping.rounded(2).description,
                shopifyFees: dayFees.rounded(2).description,
                gatewayFees: "0",
                adSpend: adSpend,
                customCosts: customCosts.description
            )
            let result = PnlEngine.compute(input)
            daily.append(DailyPnl(date: day, input: input, result: result))

            coverageSeries["meta"]?.append(96 + rng.double() * 3.4)
            coverageSeries["google"]?.append(93 + rng.double() * 4)
            coverageSeries["tiktok"]?.append(89 + rng.double() * 5)
        }

        let avgCoverage = coverageSeries.mapValues { $0.reduce(0, +) / Double($0.count) }
        let overall = (avgCoverage["meta"]! + avgCoverage["google"]! + avgCoverage["tiktok"]!) / 3
        let trust = TrustInfo(coveragePct: overall, payoutDelta: "0.4%")

        return PnlSnapshot(
            generatedAt: Date(),
            isDemo: true,
            currency: "USD",
            days: daily,
            orders: orders,
            trust: trust
        )
    }
}

struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state >> 11
    }

    mutating func double() -> Double {
        Double(next() % 1_000_000) / 1_000_000
    }

    mutating func int(in range: ClosedRange<Int>) -> Int {
        range.lowerBound + Int(next() % UInt64(range.count))
    }
}

extension Decimal {
    func rounded(_ places: Int) -> Decimal {
        let handler = NSDecimalNumberHandler(roundingMode: .bankers, scale: Int16(places),
                                             raiseOnExactness: false, raiseOnOverflow: false,
                                             raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: self).rounding(accordingToBehavior: handler).decimalValue
    }
}
