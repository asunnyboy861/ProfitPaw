import SwiftUI

struct TrustBadgeView: View {
    let coverage: Double

    private var level: TrustLevel {
        switch coverage {
        case ..<90: return .incomplete
        case ..<97: return .pending
        default: return .good
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.caption)
            Text(badgeText)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(badgeColor.opacity(0.14), in: Capsule())
        .foregroundStyle(badgeColor)
        .accessibilityLabel("Data trust: \(badgeText)")
    }

    private var badgeText: String {
        switch level {
        case .good: return "Data trust: \(String(format: "%.0f%%", coverage))"
        case .pending: return "\(String(format: "%.0f%%", coverage)) — some spend pending verification"
        case .incomplete: return "\(String(format: "%.0f%%", coverage)) — data incomplete"
        }
    }

    private var iconName: String {
        switch level {
        case .good: return "checkmark.seal.fill"
        case .pending: return "exclamationmark.triangle.fill"
        case .incomplete: return "exclamationmark.octagon.fill"
        }
    }

    private var badgeColor: Color {
        switch level {
        case .good: return Color("ProfitGreen")
        case .pending: return .orange
        case .incomplete: return Color("LossRed")
        }
    }
}

struct ShibaMascotView: View {
    let isProfitable: Bool
    @State private var bounce = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.12))
                .frame(width: 64, height: 64)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 30))
                .foregroundStyle(Color.accentColor)
                .rotationEffect(.degrees(isProfitable ? 0 : -12))
                .scaleEffect(isProfitable ? (bounce ? 1.15 : 1.0) : 0.92)
                .offset(y: isProfitable ? (bounce ? -4 : 0) : 2)
                .opacity(isProfitable ? 1 : 0.65)
                .animation(isProfitable ? .spring(response: 0.4, dampingFraction: 0.45).repeatForever(autoreverses: true) : .easeOut(duration: 0.3), value: bounce)
                .animation(.easeInOut(duration: 0.4), value: isProfitable)
        }
        .onAppear { bounce = isProfitable }
        .onChange(of: isProfitable) { _, newValue in
            bounce = newValue
        }
        .accessibilityLabel(isProfitable ? "You made a profit today" : "You lost money today")
    }
}

struct BigNumberText: View {
    let value: Decimal
    let currency: String

    var body: some View {
        Text(value, format: .currency(code: currency))
            .font(.system(size: 56, weight: .bold, design: .rounded))
            .contentTransition(.numericText())
            .animation(.snappy, value: value)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .accessibilityLabel("Net profit \(value, format: .currency(code: currency))")
    }
}
