import Foundation

struct AdSpend: Codable, Equatable {
    var meta: String
    var google: String
    var tiktok: String

    static let zero = AdSpend(meta: "0", google: "0", tiktok: "0")

    var total: Decimal {
        PnlEngine.decimal(meta) + PnlEngine.decimal(google) + PnlEngine.decimal(tiktok)
    }
}

struct DailyPnlInput: Codable, Equatable {
    var revenue: String
    var discounts: String
    var refunds: String
    var refundsCogs: String
    var cogs: String
    var shipping: String
    var shopifyFees: String
    var gatewayFees: String
    var adSpend: AdSpend
    var customCosts: String

    static let empty = DailyPnlInput(
        revenue: "0", discounts: "0", refunds: "0", refundsCogs: "0", cogs: "0",
        shipping: "0", shopifyFees: "0", gatewayFees: "0", adSpend: .zero, customCosts: "0"
    )
}

struct PnlResult: Codable, Equatable {
    var netRevenue: Decimal
    var netProfit: Decimal
    var marginPct: Decimal
    var breakEvenRoas: Decimal
}

struct DailyPnl: Identifiable, Codable, Equatable {
    var id: Date { date }
    var date: Date
    var input: DailyPnlInput
    var result: PnlResult
}

struct LineItem: Codable, Equatable {
    var sku: String
    var title: String
    var qty: Int
    var unitPrice: String
    var unitCost: String
}

struct OrderRecord: Identifiable, Codable, Equatable {
    var id: String
    var date: Date
    var number: String
    var lines: [LineItem]
    var discount: String
    var refundAmount: String
    var refundedCogs: String
    var shippingLabel: String
    var paymentFee: String

    var revenueGross: Decimal {
        lines.reduce(Decimal.zero) { $0 + PnlEngine.decimal($1.unitPrice) * Decimal($1.qty) }
    }
}

struct ProductPnl: Identifiable, Equatable {
    var id: String { sku }
    var sku: String
    var title: String
    var units: Int
    var revenue: Decimal
    var cogs: Decimal
    var profit: Decimal
    var breakEvenRoas: Decimal
}

struct CampaignPnl: Identifiable, Equatable {
    var id: String { platform }
    var platform: String
    var spend: Decimal
}

struct WaterfallStep: Identifiable, Equatable {
    var id: String { label }
    var label: String
    var amount: Decimal
    var isTotal: Bool
    var explainer: String
}

struct TrustInfo: Codable, Equatable {
    var coveragePct: Double
    var payoutDelta: String

    var level: TrustLevel {
        switch coveragePct {
        case ..<90: return .incomplete
        case ..<97: return .pending
        default: return .good
        }
    }
}

enum TrustLevel: String, Codable {
    case good, pending, incomplete
}

struct PnlSnapshot: Codable, Equatable {
    var generatedAt: Date
    var isDemo: Bool
    var currency: String
    var days: [DailyPnl]
    var orders: [OrderRecord]
    var trust: TrustInfo

    static let empty = PnlSnapshot(
        generatedAt: Date(timeIntervalSince1970: 0),
        isDemo: true, currency: "USD", days: [], orders: [],
        trust: TrustInfo(coveragePct: 0, payoutDelta: "0")
    )
}

struct ProfitAnswer: Codable, Equatable {
    var summary: String
    var evidence: [String]
}

struct Recommendation: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var why: String
    var evidence: [String]
    var expectedImpactPct: Double
}

struct InvoiceItem: Codable, Equatable {
    var skuGuess: String
    var itemDescription: String
    var unitCost: String
    var currency: String
    var qty: Int

    enum CodingKeys: String, CodingKey {
        case skuGuess = "sku_guess"
        case itemDescription = "description"
        case unitCost = "unit_cost"
        case currency
        case qty
    }
}

struct GLMChatMessage: Codable {
    var role: String
    var content: String
}

struct GLMResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            var content: String?
        }
        var message: Message
    }
    var choices: [Choice]
}

enum CloudError: LocalizedError {
    case rejected(Int)
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .rejected(let code) where code == 429:
            return "Cloud AI rate limit reached (30/hour). Your plan quota resets later, or add your own API key in Settings for unlimited use."
        case .rejected(let code) where code == 401 || code == 403:
            return "Cloud AI is not configured for this build. Add your own API key in Settings for unlimited AI."
        case .rejected(let code):
            return "Cloud AI request failed (HTTP \(code)). Please try again later."
        case .notConfigured:
            return "Cloud AI is not available in this build. Add your own API key in Settings for unlimited AI."
        }
    }
}
