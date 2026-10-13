import Foundation

enum PnlEngine {
    static func decimal(_ s: String) -> Decimal {
        let cleaned = s.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        if let d = Decimal(string: cleaned) { return d }
        return Decimal.zero
    }

    static func compute(_ i: DailyPnlInput) -> PnlResult {
        let revenue = decimal(i.revenue)
        let discounts = decimal(i.discounts)
        let refunds = decimal(i.refunds)
        let refundsCogs = decimal(i.refundsCogs)
        let cogs = decimal(i.cogs)
        let shipping = decimal(i.shipping)
        let shopifyFees = decimal(i.shopifyFees)
        let gatewayFees = decimal(i.gatewayFees)
        let customCosts = decimal(i.customCosts)

        let netRevenue = revenue - discounts - refunds
        let cogsNet = cogs - refundsCogs
        let adSpend = i.adSpend.total
        let fees = shopifyFees + gatewayFees
        let netProfit = netRevenue - cogsNet - shipping - fees - adSpend - customCosts
        let margin = netRevenue == 0 ? Decimal.zero : (netProfit / netRevenue * 100)
        let denominator = netRevenue - cogsNet - shipping - fees - customCosts
        let breakEven = denominator == 0 ? Decimal.zero : (netRevenue / denominator)
        return PnlResult(netRevenue: netRevenue, netProfit: netProfit, marginPct: margin, breakEvenRoas: breakEven)
    }

    static func waterfall(for i: DailyPnlInput) -> [WaterfallStep] {
        let r = compute(i)
        var steps: [WaterfallStep] = []
        steps.append(WaterfallStep(label: "Revenue", amount: decimal(i.revenue), isTotal: false,
            explainer: "What customers paid before any deductions. Competitor dashboards usually stop here."))
        if decimal(i.discounts) > 0 {
            steps.append(WaterfallStep(label: "Discounts", amount: -decimal(i.discounts), isTotal: false,
                explainer: "Coupon and sale codes you gave away at checkout."))
        }
        steps.append(WaterfallStep(label: "Refunds", amount: -decimal(i.refunds), isTotal: false,
            explainer: "Money returned to customers. Product costs for refunded items are added back below."))
        steps.append(WaterfallStep(label: "COGS", amount: -decimal(i.cogs), isTotal: false,
            explainer: "Cost of goods sold — what the products themselves cost you."))
        steps.append(WaterfallStep(label: "Shipping", amount: -decimal(i.shipping), isTotal: false,
            explainer: "What you paid for shipping labels, not what customers paid you."))
        steps.append(WaterfallStep(label: "Fees", amount: -(decimal(i.shopifyFees) + decimal(i.gatewayFees)), isTotal: false,
            explainer: "Payment processing fees from Shopify Payments and other gateways."))
        let ad = i.adSpend.total
        if ad > 0 {
            steps.append(WaterfallStep(label: "Ad Spend", amount: -ad, isTotal: false,
                explainer: "Total account spend across Meta, Google and TikTok — the full amount, not an attribution estimate."))
        }
        if decimal(i.customCosts) > 0 {
            steps.append(WaterfallStep(label: "Other Costs", amount: -decimal(i.customCosts), isTotal: false,
                explainer: "Custom costs such as VAT, software subscriptions or payroll you recorded."))
        }
        steps.append(WaterfallStep(label: "Net Profit", amount: r.netProfit, isTotal: true,
            explainer: "What you actually kept. This is the number that pays the bills."))
        return steps
    }

    static func productBreakEvenRoas(netRevenue: Decimal, cogsNet: Decimal, shareOfOverheads: Decimal) -> Decimal {
        let denominator = netRevenue - cogsNet - shareOfOverheads
        return denominator == 0 ? Decimal.zero : netRevenue / denominator
    }
}
