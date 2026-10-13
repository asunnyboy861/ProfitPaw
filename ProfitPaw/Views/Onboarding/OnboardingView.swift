import SwiftUI

struct OnboardingView: View {
    @State private var page = 0
    @State private var connectEndpoint = ""
    @State private var showConnectSheet = false

    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcomePage.tag(0)
                choosePage.tag(1)
                perksPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showConnectSheet) {
            connectSheet
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 18) {
            Spacer()
            ShibaMascotView(isProfitable: true)
            Text("ProfitPaw")
                .font(.largeTitle.bold())
            Text("Stop guessing. Start knowing.")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Your Shopify store's true net profit — ads, COGS, shipping and fees included — in one honest number.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }

    private var choosePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("See your real profit")
                .font(.title.bold())
            Button {
                finish(demo: true)
            } label: {
                VStack(spacing: 6) {
                    Label("Try the Demo Store", systemImage: "cart.circle.fill")
                        .font(.headline)
                    Text("Real profit calculations on sample sales — explore everything instantly")
                        .font(.caption)
                        .opacity(0.85)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)

            Button {
                showConnectSheet = true
            } label: {
                VStack(spacing: 6) {
                    Label("Connect a Shopify Store", systemImage: "link.circle.fill")
                        .font(.headline)
                    Text("Enter your aggregation endpoint from the web dashboard")
                        .font(.caption)
                        .opacity(0.85)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 24)
            Spacer()
            Spacer()
        }
    }

    private var connectSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://your-dashboard.example.com", text: $connectEndpoint)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Aggregation API endpoint")
                } footer: {
                    Text("Connect your store through the ProfitPaw web dashboard first — it generates a read-only endpoint for this app. You can also explore the demo store and connect later in Settings.")
                }
                Button("Connect") {
                    finish(demo: false, endpoint: connectEndpoint)
                }
                .disabled(connectEndpoint.isEmpty)
            }
            .navigationTitle("Connect Store")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private var perksPage: some View {
        VStack(spacing: 22) {
            Spacer()
            Text("Built for peace of mind")
                .font(.title.bold())
            perk(icon: "sparkles", title: "On-device AI", body: "Ask \"which product made the most money?\" — answered privately on your iPhone.")
            perk(icon: "widget.small", title: "Home Screen Widget", body: "Glance at today's real profit without opening the app.")
            perk(icon: "bell.badge", title: "Gentle alerts", body: "A daily digest and spend-anomaly warnings — never spam.")
            Spacer()
            Button {
                finish(demo: true)
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 24)
    }

    private func perk(icon: String, title: String, body: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(body).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 28)
    }

    private func finish(demo: Bool, endpoint: String = "") {
        AppSettings.demoMode = demo
        AppSettings.serverEndpoint = endpoint
        AppSettings.onboarded = true
        onFinish()
    }
}
