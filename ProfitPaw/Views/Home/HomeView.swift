import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.snapshot.isDemo {
                        demoBanner
                    }
                    bigNumberCard
                    if let today = viewModel.today {
                        NavigationLink {
                            MoneyTrailView(snapshot: viewModel.snapshot, date: today.date)
                        } label: {
                            HStack {
                                Text("View money trail")
                                Image(systemName: "arrow.right")
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                        }
                        .accessibilityLabel("View the money trail waterfall for today")
                        miniTrendCard
                    }
                    if let error = viewModel.loadError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color("LossRed"))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("ProfitPaw")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .accessibilityLabel("Refresh data")
                }
            }
            .refreshable { await viewModel.refresh() }
            .task { await viewModel.loadCachedThenRefresh() }
            .sheet(item: stepBinding) { step in
                StepExplainerView(step: step)
                    .presentationDetents([.height(220)])
            }
        }
    }

    private var stepBinding: Binding<WaterfallStep?> {
        Binding(get: { viewModel.selectedStep }, set: { viewModel.selectedStep = $0 })
    }

    private var demoBanner: some View {
        NavigationLink {
            Text("Connect your real store from the web dashboard, or configure a data endpoint in Settings. The demo store shows real computed profit analytics on sample sales data.")
                .font(.callout)
                .padding()
                .navigationTitle("Demo Store")
                .navigationBarTitleDisplayMode(.inline)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "cart.circle.fill")
                Text("Demo Store — sample data, real calculations")
                    .font(.footnote.weight(.medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.secondary)
        }
        .accessibilityLabel("Demo store information")
    }

    private var bigNumberCard: some View {
        VStack(spacing: 6) {
            ShibaMascotView(isProfitable: viewModel.isProfitable)
            Text("Today's Real Profit")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let today = viewModel.today {
                BigNumberText(value: today.result.netProfit, currency: viewModel.snapshot.currency)
                let delta = viewModel.aggregator.wowDeltaPct
                HStack(spacing: 4) {
                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text(String(format: "%.0f%% vs last week", abs(delta) * 100))
                        .font(.footnote.weight(.medium))
                }
                .foregroundStyle(delta >= 0 ? Color("ProfitGreen") : Color("LossRed"))
                TrustBadgeView(coverage: viewModel.snapshot.trust.coveragePct)
                VStack(spacing: 8) {
                    WaterfallChart(steps: PnlEngine.waterfall(for: today.input)) { step in
                        viewModel.selectedStep = step
                    }
                    .frame(height: 220)
                    Text("Tap a bar to learn what that money is")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.isLoading {
                ProgressView("Fetching your money trail...")
                    .padding(.vertical, 60)
            } else {
                Text("No data yet — pull to refresh.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var miniTrendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 7 days")
                .font(.headline)
            MiniTrendChart(points: viewModel.trendPoints)
                .frame(height: 140)
            if let roas = viewModel.today?.result.breakEvenRoas, roas > 0 {
                HStack {
                    Label("Break-even ROAS \(roas, format: .number.precision(.fractionLength(2)))", systemImage: "target")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("POAS \(viewModel.aggregator.storePOAS, format: .number.precision(.fractionLength(2)))")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct StepExplainerView: View {
    let step: WaterfallStep

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(step.label)
                    .font(.title3.bold())
                Spacer()
                Text(step.amount, format: .currency(code: "USD"))
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(step.isTotal ? Color.accentColor : (step.amount >= 0 ? Color("ProfitGreen") : Color("LossRed")))
            }
            Text(step.explainer)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
