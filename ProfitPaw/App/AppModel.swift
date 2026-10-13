import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var snapshot: PnlSnapshot = .empty
    @Published var isLoading = false

    func loadCached() {
        if let cached = SnapshotStore.load() {
            snapshot = cached
        }
    }

    func refresh() async {
        isLoading = true
        do {
            let provider = StoreDataProviderFactory.make()
            let fresh = try await provider.fetchSnapshot()
            snapshot = fresh
            SnapshotStore.save(fresh)
            NotificationService.scheduleDailyDigest(snapshot: fresh)
        } catch {
            if snapshot.days.isEmpty, !AppSettings.demoMode {
                AppSettings.demoMode = true
                snapshot = DemoStore.generate()
                SnapshotStore.save(snapshot)
            }
        }
        isLoading = false
    }
}
