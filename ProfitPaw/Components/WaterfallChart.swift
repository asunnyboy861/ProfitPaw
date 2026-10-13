import SwiftUI
import Charts

struct WaterfallChart: View {
    let steps: [WaterfallStep]
    var onTap: ((WaterfallStep) -> Void)?

    var body: some View {
        Chart {
            ForEach(runningSteps) { item in
                BarMark(
                    x: .value("Step", item.step.label),
                    yStart: .value("Start", item.start),
                    yEnd: .value("End", item.end),
                    width: .ratio(0.62)
                )
                .foregroundStyle(barColor(item.step))
                .cornerRadius(4)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(abbreviated(v))
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        guard let onTap else { return }
                        guard let plot = proxy.plotFrame else { return }
                        let frame = geo[plot]
                        guard frame.contains(location) else { return }
                        let width = frame.width
                        let idx = Int((location.x - frame.minX) / width * Double(runningSteps.count))
                        guard idx >= 0 && idx < runningSteps.count else { return }
                        onTap(runningSteps[idx].step)
                    }
            }
        }
    }

    private struct RunningStep: Identifiable {
        var id: String { step.label }
        let step: WaterfallStep
        let start: Double
        let end: Double
    }

    private var runningSteps: [RunningStep] {
        var cumulative = 0.0
        var result: [RunningStep] = []
        for step in steps {
            let amount = NSDecimalNumber(decimal: step.amount).doubleValue
            if step.isTotal {
                result.append(RunningStep(step: step, start: 0, end: cumulative))
            } else {
                let start = cumulative
                cumulative += amount
                result.append(RunningStep(step: step, start: min(start, cumulative), end: max(start, cumulative)))
            }
        }
        return result
    }

    private func barColor(_ step: WaterfallStep) -> Color {
        if step.isTotal { return Color.accentColor }
        return step.amount >= 0 ? Color("ProfitGreen") : Color("LossRed")
    }

    private func abbreviated(_ v: Double) -> String {
        let absV = abs(v)
        if absV >= 1000 { return String(format: "$%.0fk", v / 1000) }
        return String(format: "$%.0f", v)
    }
}

struct MiniTrendChart: View {
    let points: [(String, Double)]

    var body: some View {
        Chart(Array(points.enumerated()), id: \.offset) { index, item in
            BarMark(
                x: .value("Day", item.0),
                y: .value("Profit", item.1)
            )
            .foregroundStyle(item.1 >= 0 ? Color("ProfitGreen") : Color("LossRed"))
            .cornerRadius(3)
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(abs(v) >= 1000 ? String(format: "$%.0fk", v / 1000) : String(format: "$%.0f", v))
                            .font(.caption2)
                    }
                }
            }
        }
    }
}
