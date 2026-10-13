import Foundation
import SwiftUI

@MainActor
final class WeeklyViewModel: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    @Published var source: String = ""
    @Published var isLoading = false

    func load(snapshot: PnlSnapshot) async {
        let weekKey = Self.currentWeekKey()
        if let cached = WeeklyCardCache.load(), cached.weekKey == weekKey {
            recommendations = cached.recommendations
            source = cached.source
            return
        }
        isLoading = true
        let agg = MetricsAggregator(snapshot: snapshot)
        let response = await AIService.deepDiagnose(aggJson: agg.minifiedJson())
        if let response, !response.answer.summary.isEmpty {
            let recs = Self.recommendations(from: response)
            recommendations = recs.isEmpty ? LocalInsightEngine.recommendations(snapshot: snapshot) : recs
            source = response.source.rawValue
        } else {
            recommendations = LocalInsightEngine.recommendations(snapshot: snapshot)
            source = AIService.Source.local.rawValue
        }
        WeeklyCardCache.save(WeeklyCardCache(weekKey: weekKey, recommendations: recommendations, source: source))
        isLoading = false
    }

    private static func recommendations(from response: AIService.Response) -> [Recommendation] {
        response.answer.evidence.enumerated().prefix(3).map { index, evidence in
            Recommendation(
                title: response.answer.summary.split(separator: "•").map { $0.trimmingCharacters(in: .whitespaces) }.elementOrNil(at: index) ?? "Action \(index + 1)",
                why: evidence,
                evidence: [evidence],
                expectedImpactPct: 0
            )
        }
    }

    static func currentWeekKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-'W'ww"
        return f.string(from: Date())
    }
}

extension Array {
    func elementOrNil(at index: Int) -> Element? {
        index < count ? self[index] : nil
    }
}
