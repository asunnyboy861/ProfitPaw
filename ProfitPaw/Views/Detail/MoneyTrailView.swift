import SwiftUI

struct MoneyTrailView: View {
    let snapshot: PnlSnapshot
    let date: Date

    @State private var selectedStep: WaterfallStep?
    @State private var showOrders = false
    @State private var showProducts = false
    @State private var showCampaigns = false

    private var aggregator: MetricsAggregator { MetricsAggregator(snapshot: snapshot) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                daySummary
                VStack(spacing: 8) {
                    WaterfallChart(steps: aggregator.waterfall(for: date)) { step in
                        selectedStep = step
                    }
                    .frame(height: 280)
                    Text("Tap any bar for a plain-English explanation")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
                TrustBadgeView(coverage: snapshot.trust.coveragePct)
                drillDownGrid
                methodologyFooter
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Money Trail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(get: { selectedStep }, set: { selectedStep = $0 })) { step in
            StepExplainerView(step: step)
                .presentationDetents([.height(220)])
        }
        .navigationDestination(isPresented: $showOrders) {
            OrderListView(orders: aggregator.orders(on: date), currency: snapshot.currency)
        }
        .navigationDestination(isPresented: $showProducts) {
            ProductListView(products: aggregator.productPnl(daysBack: 30), currency: snapshot.currency)
        }
        .navigationDestination(isPresented: $showCampaigns) {
            CampaignListView(campaigns: aggregator.campaignPnl(daysBack: 30), poas: aggregator.storePOAS, currency: snapshot.currency)
        }
    }

    private var daySummary: some View {
        VStack(spacing: 4) {
            Text(dayTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let day = aggregator.day(on: date) {
                Text(day.result.netProfit, format: .currency(code: snapshot.currency))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(day.result.netProfit >= 0 ? Color("ProfitGreen") : Color("LossRed"))
                Text("Net margin \(day.result.marginPct, format: .number.precision(.fractionLength(1)))%")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var dayTitle: String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private var drillDownGrid: some View {
        VStack(spacing: 10) {
            drillButton("Order-level detail", icon: "receipts.list", subtitle: "Every order, its fees, COGS and net") {
                showOrders = true
            }
            drillButton("Product profitability", icon: "shippingbox", subtitle: "Break-even ROAS per product") {
                showProducts = true
            }
            drillButton("Ad platforms", icon: "megaphone", subtitle: "Account-total spend and store POAS") {
                showCampaigns = true
            }
        }
    }

    private func drillButton(_ title: String, icon: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 36)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(.primary)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(subtitle)")
    }

    private var methodologyFooter: some View {
        Text("Refunds reduce revenue and proportionally return COGS. Ad spend uses full account totals — never attribution estimates. Daily buckets use store-local time.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.bottom, 12)
    }
}

struct OrderListView: View {
    let orders: [OrderRecord]
    let currency: String

    var body: some View {
        List(orders) { order in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(order.number).font(.headline)
                    Spacer()
                    let net = orderNet(order)
                    Text(net, format: .currency(code: currency))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(net >= 0 ? Color("ProfitGreen") : Color("LossRed"))
                }
                Text(order.lines.map { "\($0.qty)× \($0.title)" }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Label("\(order.lines.reduce(0) { $0 + $1.qty }) units", systemImage: "shippingbox")
                    Label("Ship $\(order.shippingLabel)", systemImage: "truck.box")
                    Label("Fee $\(order.paymentFee)", systemImage: "creditcard")
                    if PnlEngine.decimal(order.refundAmount) > 0 {
                        Label("Refund $\(order.refundAmount)", systemImage: "arrow.uturn.left")
                            .foregroundStyle(Color("LossRed"))
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Orders")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func orderNet(_ order: OrderRecord) -> Decimal {
        let gross = order.revenueGross - PnlEngine.decimal(order.discount) - PnlEngine.decimal(order.refundAmount)
        let cogs = order.lines.reduce(Decimal.zero) { $0 + PnlEngine.decimal($1.unitCost) * Decimal($1.qty) } - PnlEngine.decimal(order.refundedCogs)
        return gross - cogs - PnlEngine.decimal(order.shippingLabel) - PnlEngine.decimal(order.paymentFee)
    }
}

struct ProductListView: View {
    let products: [ProductPnl]
    let currency: String

    var body: some View {
        List(products) { product in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(product.title).font(.headline)
                    Spacer()
                    Text(product.profit, format: .currency(code: currency))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(product.profit >= 0 ? Color("ProfitGreen") : Color("LossRed"))
                }
                HStack(spacing: 12) {
                    Text("\(product.units) units")
                    Text("Revenue $\(product.revenue)")
                    Text("COGS $\(product.cogs)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Label("Break-even ROAS \(product.breakEvenRoas, format: .number.precision(.fractionLength(2)))", systemImage: "target")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Products (30d)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CampaignListView: View {
    let campaigns: [CampaignPnl]
    let poas: Decimal
    let currency: String

    var body: some View {
        List(campaigns) { campaign in
            HStack {
                Image(systemName: platformIcon(campaign.platform))
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading) {
                    Text(campaign.platform).font(.headline)
                    Text("Account total spend — no attribution estimates")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(campaign.spend, format: .currency(code: currency))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Ad Platforms (30d)")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Text("Store POAS (Profit on Ad Spend)")
                    .font(.subheadline)
                Spacer()
                Text(poas, format: .number.precision(.fractionLength(2)))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.accentColor)
            }
            .padding()
            .background(.bar)
        }
    }

    private func platformIcon(_ platform: String) -> String {
        switch platform {
        case "Meta": return "f.circle.fill"
        case "Google": return "g.circle.fill"
        case "TikTok": return "t.circle.fill"
        default: return "megaphone.fill"
        }
    }
}
