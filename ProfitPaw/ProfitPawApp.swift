import SwiftUI
import LocalAuthentication
import BackgroundTasks

@main
struct ProfitPawApp: App {
    @StateObject private var appModel = AppModel()
    @AppStorage("onboarded") private var onboarded = false
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var isLocked = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !onboarded {
                    OnboardingView {
                        onboarded = true
                    }
                    .task { await appModel.refresh() }
                } else if isLocked {
                    lockScreen
                } else {
                    MainTabView()
                        .environmentObject(appModel)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: onboarded)
            .animation(.easeInOut(duration: 0.25), value: isLocked)
            .onChange(of: scenePhase) { _, phase in
                guard onboarded else { return }
                if phase == .background && appLockEnabled {
                    isLocked = true
                }
                if phase == .active {
                    Task {
                        appModel.loadCached()
                        await appModel.refresh()
                    }
                }
            }
            .task {
                appModel.loadCached()
                if AppSettings.pushEnabled {
                    NotificationService.registerForRemoteNotifications()
                }
            }
        }
    }

    private var lockScreen: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "pawprint.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
            Text("ProfitPaw is locked")
                .font(.title3.bold())
            Button {
                authenticate()
            } label: {
                Label("Unlock", systemImage: "faceid")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear { authenticate() }
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock your profit dashboard") { success, _ in
                Task { @MainActor in
                    if success {
                        isLocked = false
                    }
                }
            }
        } else {
            isLocked = false
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            AskView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Ask")
                }
            WeeklyReportView()
                .tabItem {
                    Image(systemName: "calendar.badge.checkmark")
                    Text("Weekly")
                }
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .tint(Color.accentColor)
    }
}
