import Foundation
import UIKit

enum PdfExporter {
    static func monthlyPDF(snapshot: PnlSnapshot, month: Date) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let cal = Calendar.current
        let monthDays = snapshot.days.filter { cal.isDate($0.date, equalTo: month, toGranularity: .month) }
        let monthOrders = snapshot.orders.filter { cal.isDate($0.date, equalTo: month, toGranularity: .month) }

        var revenue = Decimal.zero, cogs = Decimal.zero, shipping = Decimal.zero
        var fees = Decimal.zero, ads = Decimal.zero, custom = Decimal.zero
        var netProfit = Decimal.zero
        for day in monthDays {
            let i = day.input
            revenue += PnlEngine.decimal(i.revenue) - PnlEngine.decimal(i.discounts) - PnlEngine.decimal(i.refunds)
            cogs += PnlEngine.decimal(i.cogs) - PnlEngine.decimal(i.refundsCogs)
            shipping += PnlEngine.decimal(i.shipping)
            fees += PnlEngine.decimal(i.shopifyFees) + PnlEngine.decimal(i.gatewayFees)
            ads += i.adSpend.total
            custom += PnlEngine.decimal(i.customCosts)
            netProfit += day.result.netProfit
        }

        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 56
            func draw(_ text: String, size: CGFloat = 11, bold: Bool = false) {
                let font = bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
                let attrs: [NSAttributedString.Key: Any] = [.font: font]
                (text as NSString).draw(at: CGPoint(x: 56, y: y), withAttributes: attrs)
                y += size + 8
            }
            let df = DateFormatter()
            df.dateFormat = "MMMM yyyy"
            draw("ProfitPaw — Accountant Summary", size: 20, bold: true)
            draw(df.string(from: month), size: 13)
            draw("Generated \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))")
            y += 12
            draw("NET REVENUE", bold: true)
            draw("  $\(revenue)")
            draw("COST OF GOODS SOLD", bold: true)
            draw("  -$\(cogs)")
            draw("SHIPPING LABELS", bold: true)
            draw("  -$\(shipping)")
            draw("PAYMENT FEES", bold: true)
            draw("  -$\(fees)")
            draw("AD SPEND (account totals)", bold: true)
            draw("  -$\(ads)")
            draw("OTHER COSTS", bold: true)
            draw("  -$\(custom)")
            y += 8
            draw("NET PROFIT", size: 16, bold: true)
            draw("  $\(netProfit)", size: 16, bold: true)
            y += 16
            draw("Orders processed: \(monthOrders.count)", size: 10)
            draw("Data trust coverage: \(String(format: "%.0f%%", snapshot.trust.coveragePct))", size: 10)
            draw("Payout reconcile delta: \(snapshot.trust.payoutDelta)", size: 10)
            y += 12
            draw("Methodology: refunds reduce revenue and proportionally reduce COGS.", size: 9)
            draw("Ad spend uses full account totals (no attribution estimates).", size: 9)
            draw("All amounts use decimal arithmetic; daily buckets use store-local time.", size: 9)
            draw("This summary is a record of activity — not accounting, tax, or investment advice.", size: 9)
        }
    }
}
