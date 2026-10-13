import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var appModel: AppModel
    @AppStorage("pushEnabled") private var pushEnabled = false
    @AppStorage("digestHour") private var digestHour = 8
    @AppStorage("anomalyMultiplier") private var anomalyMultiplier = 2.0
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @AppStorage("serverEndpoint") private var serverEndpoint = ""
    @AppStorage("demoMode") private var demoMode = true
    @State private var showExporter = false
    @State private var showUnlock = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private let policyBase = "https://asunnyboy861.github.io/ProfitPaw"

    var body: some View {
        NavigationStack {
            Form {
                dataSection
                aiSection
                toolsSection
                notificationsSection
                planSection
                legalSection
                supportSection
                aboutSection
            }
            .navigationTitle("Settings")
            .fileExporter(isPresented: $showExporter, document: ProfitPawPDF(data: pdfData), contentType: .pdf, defaultFilename: "ProfitPaw-Accountant") { _ in }
        }
    }

    private var pdfData: Data {
        PdfExporter.monthlyPDF(snapshot: appModel.snapshot, month: Date())
    }

    private var dataSection: some View {
        Section("Data") {
            Toggle("Use Demo Store", isOn: $demoMode)
                .accessibilityHint("Sample data with real profit calculations")
            if !demoMode {
                TextField("Aggregation API endpoint (https://...)", text: $serverEndpoint)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            HStack {
                Text("Snapshot")
                Spacer()
                Text(appModel.snapshot.generatedAt == Date(timeIntervalSince1970: 0) ? "Not loaded" : appModel.snapshot.generatedAt.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }
            Button("Reload Data") {
                Task { await appModel.refresh() }
            }
        }
    }

    private var aiSection: some View {
        Section {
            NavigationLink {
                AISettingsView()
            } label: {
                HStack {
                    Image(systemName: "sparkles").foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Settings").font(.headline)
                        Text(appleStatusText).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityLabel("AI Settings: \(appleStatusText)")
        } header: {
            Text("AI")
        } footer: {
            Text("Apple Intelligence answers on-device for free. Add your own API key for unlimited cloud AI — BYO usage is never counted against any plan.")
        }
    }

    private var appleStatusText: String {
        AIService.appleIntelligenceAvailable ? "Apple Intelligence available (iOS 26+)" : "Apple Intelligence unavailable — BYO key recommended"
    }

    private var toolsSection: some View {
        Section("AI Tools") {
            NavigationLink {
                InvoiceScanView()
            } label: {
                HStack {
                    Image(systemName: "camera.viewfinder").foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scan Invoice").font(.headline)
                        Text("Photo → AI-extracted item costs").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Button {
                showExporter = true
            } label: {
                HStack {
                    Image(systemName: "doc.richtext").foregroundStyle(Color.accentColor)
                    Text("Export Accountant PDF (this month)")
                }
            }
            .accessibilityLabel("Export accountant PDF for this month")
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle("Daily Profit Digest", isOn: $pushEnabled)
            if pushEnabled {
                Stepper(value: $digestHour, in: 5...21) {
                    Text("Digest time: \(digestHour):00")
                }
                VStack(alignment: .leading) {
                    HStack {
                        Text("Alert when today's ad spend exceeds")
                        Spacer()
                        Text(String(format: "%.1fx daily avg", anomalyMultiplier))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $anomalyMultiplier, in: 1.2...4.0, step: 0.1)
                        .accessibilityLabel("Anomaly multiplier")
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("The digest summarizes yesterday's profit and your top product. Anomaly alerts fire locally from your latest data.")
        }
        .onChange(of: pushEnabled) { _, enabled in
            if enabled {
                Task {
                    let granted = await NotificationService.requestAuthorization()
                    if granted {
                        NotificationService.registerForRemoteNotifications()
                        NotificationService.scheduleDailyDigest(snapshot: appModel.snapshot)
                    }
                }
            }
        }
        .onChange(of: digestHour) { _, _ in
            NotificationService.scheduleDailyDigest(snapshot: appModel.snapshot)
        }
        .onChange(of: anomalyMultiplier) { _, _ in
            NotificationService.checkSpendAnomaly(snapshot: appModel.snapshot)
        }
    }

    private var planSection: some View {
        Section {
            HStack {
                Image(systemName: "crown.fill").foregroundStyle(Color.accentColor)
                Text("Current Plan")
                Spacer()
                Text(planName).foregroundStyle(.secondary)
            }
            Text("Manage your plan on the web dashboard. This app never sells anything in-app.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Plan")
        }
    }

    private var planName: String {
        appModel.snapshot.isDemo ? "Demo Store" : "Connected"
    }

    private var legalSection: some View {
        Section("Legal") {
            Link(destination: URL(string: "\(policyBase)/privacy.html")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Link(destination: URL(string: "\(policyBase)/support.html")!) {
                Label("Support", systemImage: "questionmark.circle")
            }
            NavigationLink {
                MethodologyView()
            } label: {
                Label("How we calculate profit", systemImage: "function")
            }
            Toggle("Lock with Face ID / Passcode", isOn: $appLockEnabled)
        }
    }

    private var supportSection: some View {
        Section("Feedback") {
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            VStack(spacing: 4) {
                Image(systemName: "pawprint.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                Text("ProfitPaw")
                    .font(.footnote.weight(.semibold))
                Text(appVersion)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Stop guessing. Start knowing.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        } footer: {
            Text("ProfitPaw provides record-keeping and analytics. It is not investment, accounting, or tax advice.")
        }
    }
}

struct ProfitPawPDF: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct MethodologyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(MethodologyView.rules, id: \.title) { rule in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rule.title).font(.headline)
                        Text(rule.body).font(.callout).foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
        }
        .navigationTitle("Profit Methodology")
        .navigationBarTitleDisplayMode(.inline)
    }

    static let rules: [(title: String, body: String)] = [
        ("Decimal money math", "Every amount is computed with decimal string arithmetic — never floating point — so totals match to the cent."),
        ("Net refunds, fully", "A refund reduces revenue AND proportionally returns COGS and fees. We never only subtract the sale."),
        ("Full ad account spend", "Ad spend is the total account consumption across Meta, Google and TikTok — never an attribution-model estimate."),
        ("Idempotent syncs", "Re-delivered data events never double-count. Every source row is keyed and upserted."),
        ("Store-local day buckets", "Daily numbers are bucketed in your store's local timezone to match Shopify Reports."),
        ("Trust badge", "Coverage = collected spend ÷ account total spend. When it drops below 97% we mark the day as pending verification instead of pretending it is right."),
        ("Replayable engine", "Raw records are the source of truth; the P&L engine is a pure function, so any formula change can recompute history.")
    ]
}
