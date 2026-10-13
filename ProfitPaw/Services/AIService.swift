import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum AIService {
    enum Source: String {
        case onDevice = "Apple Intelligence"
        case byo = "Your API Key"
        case cloud = "Cloud AI"
        case local = "Offline Insights"
    }

    struct Response {
        let answer: ProfitAnswer
        let source: Source
    }

    static var appleIntelligenceAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    static func ask(_ question: String, context: String) async -> Response? {
        if appleIntelligenceAvailable {
            #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
                if let answer = try? await askOnDevice(question, context: context) {
                    return Response(answer: answer, source: .onDevice)
                }
            }
            #endif
        }
        let providers = BYOStore.load()
        if let provider = BYOStore.defaultProvider(for: .diagnose, in: providers) {
            if let answer = try? await BYOClient.answer(provider, question: question, context: context) {
                return Response(answer: answer, source: .byo)
            }
        }
        return nil
    }

    static func deepDiagnose(aggJson: String) async -> Response? {
        if GLMCloud.isConfigured {
            if let recs = try? await GLMCloud.diagnose(aggJson: aggJson), !recs.isEmpty {
                let answer = ProfitAnswer(summary: recs.map(\.title).joined(separator: " • "), evidence: recs.flatMap(\.evidence))
                return Response(answer: answer, source: .cloud)
            }
        }
        let providers = BYOStore.load()
        if let provider = BYOStore.defaultProvider(for: .diagnose, in: providers) {
            if let answer = try? await BYOClient.answer(provider, question: "Give exactly 3 actionable profit recommendations citing specific numbers.", context: aggJson) {
                return Response(answer: answer, source: .byo)
            }
        }
        return nil
    }

    static func scanInvoice(imageBase64: String) async throws -> (items: [InvoiceItem], source: Source) {
        let providers = BYOStore.load()
        if let provider = BYOStore.defaultProvider(for: .invoice, in: providers) {
            let items = try await BYOClient.scanInvoice(provider, imageBase64: imageBase64)
            return (items, .byo)
        }
        if GLMCloud.isConfigured {
            let items = try await GLMCloud.extractInvoice(imageBase64: imageBase64)
            return (items, .cloud)
        }
        throw CloudError.notConfigured
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func askOnDevice(_ question: String, context: String) async throws -> ProfitAnswer {
        let session = LanguageModelSession()
        let instructions = """
        You are a DTC profit analyst answering merchant questions about their Shopify store.
        Use ONLY the provided data snapshot. Be conversational and cite concrete numbers.
        """
        let prompt = """
        \(instructions)

        Question: \(question)

        Data snapshot: \(context)
        """
        let answer = try await session.respond(to: prompt, generating: OnDeviceProfitAnswer.self)
        return ProfitAnswer(summary: answer.content.summary, evidence: answer.content.evidence)
    }
    #endif
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct OnDeviceProfitAnswer {
    @Guide(description: "One-sentence conversational conclusion with concrete numbers")
    var summary: String
    @Guide(description: "Number-backed supporting facts, like 'Cozy Hoodie: $210 profit'")
    var evidence: [String]
}
#endif

enum LocalInsightEngine {
    static func recommendations(snapshot: PnlSnapshot) -> [Recommendation] {
        let agg = MetricsAggregator(snapshot: snapshot)
        var recs: [Recommendation] = []
        let products = agg.productPnl(daysBack: 30)
        if let top = products.first, top.units > 0 {
            recs.append(Recommendation(
                title: "Double down on \(top.title)",
                why: "It generated $\(top.profit) of profit in the last 30 days on \(top.units) units — your strongest earner. Increase its ad budget or feature it in email campaigns.",
                evidence: ["\(top.title): $\(top.profit) profit", "\(top.units) units sold in 30 days", "Break-even ROAS: \(top.breakEvenRoas)"],
                expectedImpactPct: 8
            ))
        }
        if let worst = products.last, products.count > 2, worst.profit < 0 {
            recs.append(Recommendation(
                title: "Review or retire \(worst.title)",
                why: "It lost $\(abs(NSDecimalNumber(decimal: worst.profit).doubleValue)) in 30 days. Either raise the price, renegotiate COGS, or cut its ad spend.",
                evidence: ["\(worst.title): $\(worst.profit) profit", "Margin is negative after COGS"],
                expectedImpactPct: 5
            ))
        }
        let campaigns = agg.campaignPnl(daysBack: 7)
        if let biggest = campaigns.first, biggest.spend > 0 {
            recs.append(Recommendation(
                title: "Check \(biggest.platform) spend efficiency",
                why: "\(biggest.platform) consumed $\(biggest.spend) in 7 days. Your store break-even ROAS is \(agg.breakEvenRoas); make sure campaigns clear it.",
                evidence: ["\(biggest.platform) 7-day spend: $\(biggest.spend)", "Store POAS: \(agg.storePOAS)", "Break-even ROAS: \(agg.breakEvenRoas)"],
                expectedImpactPct: 12
            ))
        }
        return Array(recs.prefix(3))
    }
}
