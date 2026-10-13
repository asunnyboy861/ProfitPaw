import AppIntents
import Foundation

struct AskProfitIntent: AppIntent {
    static var title: LocalizedStringResource = "Today's Real Profit"
    static var description = IntentDescription("Ask how profitable your store was today.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshot = SnapshotStore.load() ?? DemoStore.generate()
        guard let today = snapshot.days.last else {
            return .result(dialog: IntentDialog("No profit data yet — open ProfitPaw to load your store."))
        }
        let aggregator = MetricsAggregator(snapshot: snapshot)
        let profit = today.result.netProfit
        let formatted = profit.formatted(.currency(code: snapshot.currency))
        let delta = aggregator.wowDeltaPct
        let direction = delta >= 0 ? "up" : "down"
        let dialog = IntentDialog("Today's real profit is \(formatted), \(direction) \(String(format: "%.0f", abs(delta) * 100))%% versus last week.")
        return .result(dialog: dialog)
    }
}

struct ProfitPawShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskProfitIntent(),
            phrases: [
                "How profitable was I today in \(.applicationName)",
                "\(.applicationName) profit today"
            ],
            shortTitle: "Today's Real Profit",
            systemImageName: "pawprint.fill"
        )
    }
}
