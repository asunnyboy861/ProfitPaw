import SwiftUI

struct AskView: View {
    @StateObject private var viewModel = AskViewModel()
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if viewModel.messages.isEmpty {
                                emptyState
                            }
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            if viewModel.isThinking {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text(viewModel.progressLine.isEmpty ? "Thinking..." : viewModel.progressLine)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let last = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                suggestionChips
                inputBar
            }
            .navigationTitle("Ask")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                viewModel.loadHistory()
                viewModel.attach(snapshot: appModel.snapshot)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            ShibaMascotView(isProfitable: true)
            Text("Ask your money anything")
                .font(.title3.bold())
            Text("On-device AI answers instantly and privately. Complex questions never leave your device unless you use a cloud key.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.suggestions, id: \.self) { suggestion in
                    Button {
                        Task { await viewModel.send(suggestion) }
                    } label: {
                        Text(suggestion)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color(.secondarySystemBackground), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Ask: \(suggestion)")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about your profit...", text: $viewModel.input, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .onSubmit {
                    Task { await viewModel.send(nil) }
                }
            Button {
                Task { await viewModel.send(nil) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
            .disabled(viewModel.input.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isThinking)
            .accessibilityLabel("Send question")
        }
        .padding()
        .background(.bar)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @State private var expanded = false

    var body: some View {
        VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
            Text(message.text)
                .font(.callout)
                .padding(12)
                .background(bubbleBackground, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(message.role == "user" ? Color.white : Color.primary)
            if message.role == "assistant" && !message.source.isEmpty {
                Text(message.source)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if !message.evidence.isEmpty {
                Button {
                    withAnimation { expanded.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: expanded ? "eye.slash" : "checkmark.seal")
                        Text(expanded ? "Hide evidence" : "Show evidence (\(message.evidence.count))")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                if expanded {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(message.evidence, id: \.self) { item in
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
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == "user" ? .trailing : .leading)
    }

    private var bubbleBackground: Color {
        message.role == "user" ? Color.accentColor : Color(.secondarySystemBackground)
    }
}
