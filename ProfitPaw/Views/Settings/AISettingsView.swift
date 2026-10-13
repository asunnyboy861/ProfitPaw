import SwiftUI

struct AISettingsView: View {
    @StateObject private var viewModel = AISettingsViewModel()
    @State private var showAddMenu = false

    var body: some View {
        Form {
            appleSection
            providerSection
            routingSection
        }
        .navigationTitle("AI Settings")
        .confirmationDialog("Add a provider", isPresented: $showAddMenu, titleVisibility: .visible) {
            ForEach(BYOProviderConfig.Preset.allCases) { preset in
                Button(preset.label) {
                    viewModel.add(preset)
                }
            }
        }
    }

    private var appleSection: some View {
        Section {
            HStack {
                Image(systemName: AIService.appleIntelligenceAvailable ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(AIService.appleIntelligenceAvailable ? Color("ProfitGreen") : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Intelligence (on-device)").font(.headline)
                    Text(appleDetail).font(.caption).foregroundStyle(.secondary)
                }
            }
        } footer: {
            Text("Daily questions run on-device: free, unlimited, and your numbers never leave the device. Requires iOS 26 or later on supported devices.")
        }
    }

    private var appleDetail: String {
        AIService.appleIntelligenceAvailable
            ? "Available — used first for every question."
            : "Unavailable on this device. Add a provider below to use AI."
    }

    private var providerSection: some View {
        Section {
            ForEach(viewModel.providers) { provider in
                NavigationLink {
                    ProviderEditView(config: provider, viewModel: viewModel)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(provider.displayName).font(.headline)
                            Text("\(provider.preset.label) · \(provider.model.isEmpty ? "no model set" : provider.model)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        statusBadge(provider.status)
                    }
                }
            }
            .onDelete { viewModel.delete(at: $0) }
            Button {
                showAddMenu = true
            } label: {
                Label("Add Provider", systemImage: "plus")
            }
            .tint(Color.accentColor)
        } header: {
            Text("Bring Your Own API (unlimited AI)")
        } footer: {
            Text("Your keys are stored in the iOS Keychain and sent only to the endpoint you choose. BYO usage is unlimited and never counted against your plan.")
        }
    }

    private func statusBadge(_ status: BYOProviderConfig.Status) -> some View {
        Group {
            switch status {
            case .verified:
                Label("Verified", systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(Color("ProfitGreen"))
            case .error:
                Label("Error", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(Color("LossRed"))
            case .unverified:
                Label("Not verified", systemImage: "circle.dashed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var routingSection: some View {
        Section {
            ForEach(BYOProviderConfig.Task.allCases, id: \.rawValue) { task in
                Picker("Default for \(task.label)", selection: routingSelection(for: task)) {
                    Text("None (smart routing)").tag("")
                    ForEach(viewModel.providers.filter { BYOStore.capability($0, task: task) }) { provider in
                        Text(provider.displayName).tag(provider.id)
                    }
                }
            }
        } header: {
            Text("Routing")
        } footer: {
            Text("Invoice scanning needs a vision-capable model. Diagnosis prefers any text model. On-device AI is always tried first.")
        }
    }

    private func routingSelection(for task: BYOProviderConfig.Task) -> Binding<String> {
        Binding(
            get: {
                viewModel.providers.first { $0.isDefaultFor.contains(task) }?.id ?? ""
            },
            set: { newValue in
                if let provider = viewModel.providers.first(where: { $0.id == newValue }) {
                    viewModel.setDefault(provider, task: task, enabled: true)
                } else {
                    viewModel.setDefault(BYOProviderConfig(id: "", preset: .custom, displayName: "", baseURL: "", model: "", apiKeyRef: "", capabilities: .init(text: true, vision: true, reasoning: true), status: .unverified, isDefaultFor: []), task: task, enabled: false)
                }
            }
        )
    }
}

struct ProviderEditView: View {
    @State var config: BYOProviderConfig
    @ObservedObject var viewModel: AISettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var verifyResult: String?

    var body: some View {
        Form {
            Section("Provider") {
                TextField("Display name", text: $config.displayName)
                TextField("Base URL", text: $config.baseURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Model", text: $config.model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            Section("API Key") {
                SecureField("API Key (stored in Keychain)", text: $apiKey)
                Button("Verify & Save") {
                    Task {
                        viewModel.saveKey(apiKey, for: config)
                        config.status = .unverified
                        await viewModel.verify(config)
                        if let updated = viewModel.providers.first(where: { $0.id == config.id }) {
                            config = updated
                        }
                        verifyResult = viewModel.providers.first(where: { $0.id == config.id })?.status == .verified ? "Connected" : "Verification failed — check key and URL"
                    }
                }
                .disabled(apiKey.isEmpty || viewModel.verifyingID == config.id)
                if viewModel.verifyingID == config.id {
                    ProgressView()
                }
                if let verifyResult {
                    Text(verifyResult)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if config.preset == .custom {
                Section("Capabilities") {
                    Toggle("Supports images (vision)", isOn: $config.capabilities.vision)
                    Toggle("Supports reasoning", isOn: $config.capabilities.reasoning)
                }
            }
            Section {
                Text("Your key is stored in the iOS Keychain and sent only to \(config.baseURL.isEmpty ? "your endpoint" : config.baseURL). BYO usage is unlimited and never counted against your plan.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Edit Provider")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            var updated = config
            updated.capabilities.text = true
            updated.capabilities.vision = config.preset == .custom ? config.capabilities.vision : updated.capabilities.vision
            if let index = viewModel.providers.firstIndex(where: { $0.id == config.id }) {
                viewModel.providers[index] = updated
                viewModel.persist()
            }
        }
    }
}
