import Foundation
import UIKit
import UserNotifications

enum NotificationService {
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    static func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    static func scheduleDailyDigest(snapshot: PnlSnapshot) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily.digest"])
        guard AppSettings.pushEnabled else { return }
        guard let last = snapshot.days.last else { return }

        let content = UNMutableNotificationContent()
        let profit = NSDecimalNumber(decimal: last.result.netProfit).doubleValue
        let top = MetricsAggregator(snapshot: snapshot).productPnl(daysBack: 1).first
        var body = String(format: "Yesterday you made $%.2f", profit)
        if let top {
            body += " — top product: \(top.title) ($\(NSDecimalNumber(decimal: top.profit)))"
        }
        content.title = "Daily Profit Digest"
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = AppSettings.digestHour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily.digest", content: content, trigger: trigger)
        center.add(request)
    }

    static func checkSpendAnomaly(snapshot: PnlSnapshot) {
        let agg = MetricsAggregator(snapshot: snapshot)
        guard let avg = try? Decimal(string: "\(agg.averageDailyAdSpend)"), avg > 0 else { return }
        let today = agg.todayAdSpend
        let ratio = NSDecimalNumber(decimal: today / avg).doubleValue
        guard ratio >= AppSettings.anomalyMultiplier else { return }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Ad Spend Anomaly"
        content.body = String(format: "Today's ad spend is %.1fx your daily average. Break-even ROAS is %.2f — review your campaigns.", ratio, NSDecimalNumber(decimal: agg.breakEvenRoas).doubleValue)
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "anomaly.spend.\(Int(Date().timeIntervalSince1970))", content: content, trigger: trigger)
        center.add(request)
    }
}
