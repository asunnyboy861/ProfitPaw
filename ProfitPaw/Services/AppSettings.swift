import Foundation

struct AppSettings {
    static var onboarded: Bool {
        get { UserDefaults.standard.bool(forKey: "onboarded") }
        set { UserDefaults.standard.set(newValue, forKey: "onboarded") }
    }

    static var demoMode: Bool {
        get { UserDefaults.standard.object(forKey: "demoMode") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "demoMode") }
    }

    static var serverEndpoint: String {
        get { UserDefaults.standard.string(forKey: "serverEndpoint") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "serverEndpoint") }
    }

    static var pushEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "pushEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "pushEnabled") }
    }

    static var digestHour: Int {
        get { UserDefaults.standard.object(forKey: "digestHour") as? Int ?? 8 }
        set { UserDefaults.standard.set(newValue, forKey: "digestHour") }
    }

    static var anomalyMultiplier: Double {
        get { UserDefaults.standard.object(forKey: "anomalyMultiplier") as? Double ?? 2.0 }
        set { UserDefaults.standard.set(newValue, forKey: "anomalyMultiplier") }
    }

    static var appLockEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "appLockEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "appLockEnabled") }
    }

    static var defaultDiagnoseProviderID: String {
        get { UserDefaults.standard.string(forKey: "defaultDiagnoseProviderID") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "defaultDiagnoseProviderID") }
    }

    static var defaultInvoiceProviderID: String {
        get { UserDefaults.standard.string(forKey: "defaultInvoiceProviderID") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "defaultInvoiceProviderID") }
    }

    static func invoiceScansThisMonth() -> Int {
        let key = "invoiceScans.\(Self.monthKey())"
        return UserDefaults.standard.integer(forKey: key)
    }

    static func incrementInvoiceScans() {
        let key = "invoiceScans.\(Self.monthKey())"
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: key) + 1, forKey: key)
    }

    private static func monthKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMM"
        return f.string(from: Date())
    }
}
