import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var snapshot: PnlSnapshot = .empty
    @Published var isLoading = false
    @Published var loadError: String?
    @Published var selectedStep: WaterfallStep?
    @Published var selectedDate: Date?

    var aggregator: MetricsAggregator { MetricsAggregator(snapshot: snapshot) }

    var today: DailyPnl? { snapshot.days.last }
    var isProfitable: Bool { (today?.result.netProfit ?? 0) >= 0 }

    var trendPoints: [(String, Double)] {
        snapshot.days.suffix(7).map { day in
            let f = DateFormatter()
            f.dateFormat = "EEE"
            return (f.string(from: day.date), NSDecimalNumber(decimal: day.result.netProfit).doubleValue)
        }
    }

    func loadCachedThenRefresh() async {
        if let cached = SnapshotStore.load() {
            snapshot = cached
        }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        loadError = nil
        do {
            let provider = StoreDataProviderFactory.make()
            let fresh = try await provider.fetchSnapshot()
            snapshot = fresh
            SnapshotStore.save(fresh)
            NotificationService.scheduleDailyDigest(snapshot: fresh)
            NotificationService.checkSpendAnomaly(snapshot: fresh)
        } catch {
            if snapshot.days.isEmpty {
                loadError = "Could not load your store data. Check your connection or Settings."
            }
        }
        isLoading = false
    }
}
