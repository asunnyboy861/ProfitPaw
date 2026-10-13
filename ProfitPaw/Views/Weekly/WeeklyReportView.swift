import SwiftUI

struct WeeklyReportView: View {
    @StateObject private var viewModel = WeeklyViewModel()
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if viewModel.isLoading {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Analyzing your week...")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if viewModel.recommendations.isEmpty {
                        Text("No insights for this week yet.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        ForEach(viewModel.recommendations) { rec in
                            ActionCard(rec: rec)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Weekly Actions")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.load(snapshot: appModel.snapshot)
            }
            .refreshable {
                WeeklyCardCache.save(WeeklyCardCache(weekKey: WeeklyViewModel.currentWeekKey(), recommendations: [], source: ""))
                await viewModel.load(snapshot: appModel.snapshot)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("3 things to do this week")
                .font(.title3.bold())
            Text("Every claim shows its evidence — tap to verify the numbers yourself.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if !viewModel.source.isEmpty {
                Label("Powered by \(viewModel.source)", systemImage: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

struct ActionCard: View {
    let rec: Recommendation
    @State private var showEvidence = false
    @State private var reminderAdded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(rec.title)
                    .font(.headline)
                Spacer()
                if rec.expectedImpactPct > 0 {
                    Text("+\(Int(rec.expectedImpactPct))% est.")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("ProfitGreen").opacity(0.14), in: Capsule())
                        .foregroundStyle(Color("ProfitGreen"))
                }
            }
            Text(rec.why)
                .font(.callout)
                .foregroundStyle(.secondary)
            if !rec.evidence.isEmpty {
                Button {
                    withAnimation { showEvidence.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal")
                        Text(showEvidence ? "Hide evidence" : "Why? Show evidence")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                if showEvidence {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(rec.evidence, id: \.self) { item in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 5))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 6)
                                Text(item)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            HStack {
                Button {
                    reminderAdded = true
                    let content = UNMutableNotificationContent()
                    content.title = "Reminder: \(rec.title)"
                    content.body = rec.why
                    content.sound = .default
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
                    UNUserNotificationCenter.current().add(
                        UNNotificationRequest(identifier: "reminder.\(rec.id.uuidString)", content: content, trigger: trigger)
                    )
                    Task {
                        await NotificationService.requestAuthorization()
                    }
                } label: {
                    Label(reminderAdded ? "Reminder set" : "Remind me", systemImage: reminderAdded ? "bell.fill" : "bell")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(Color.accentColor)
                .disabled(reminderAdded)
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}

import UserNotifications
