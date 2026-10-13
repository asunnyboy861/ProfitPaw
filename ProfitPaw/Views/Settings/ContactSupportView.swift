import SwiftUI

struct ContactSupportView: View {
    enum Subject: String, CaseIterable, Identifiable {
        case general = "General"
        case feature = "Feature Suggestion"
        case bug = "Bug Report"
        case usage = "Usage Question"
        case performance = "Performance Issue"
        case ui = "UI Improvement"
        case other = "Other"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general: return "bubble.left.fill"
            case .feature: return "lightbulb.fill"
            case .bug: return "ant.fill"
            case .usage: return "questionmark.circle.fill"
            case .performance: return "gauge.with.dots.needle.67percent"
            case .ui: return "paintpalette.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }

    @State private var subject: Subject = .general
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var result: SubmitResult?
    @State private var emailHint = false

    private let maxMessageLength = 1000

    private struct SubmitResult: Equatable {
        let success: Bool
        let text: String
    }

    private var emailValid: Bool {
        email.contains("@") && email.contains(".") && email.count > 4
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && emailValid
            && !message.trimmingCharacters(in: .whitespaces).isEmpty
            && (subject != .other || !customSubject.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    var body: some View {
        Form {
            Section {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach([Subject.general, .feature, .bug, .usage, .performance, .ui]) { item in
                        subjectTile(item)
                    }
                    subjectTile(.other)
                        .frame(maxWidth: .infinity)
                        .gridCellColumns(2)
                }
                if subject == .other {
                    TextField("Custom subject", text: $customSubject)
                        .accessibilityLabel("Custom subject")
                }
            } header: {
                Text("Subject")
            }

            Section {
                TextField("Your name", text: $name)
                    .textInputAutocapitalization(.words)
                    .accessibilityLabel("Your name")
            }
            Section {
                TextField("yourname@example.com", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Email address")
                    .onChange(of: email) { _, newValue in
                        emailHint = !newValue.isEmpty && !emailValid
                    }
                if emailHint {
                    Label("Enter a valid email so we can reply.", systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundStyle(Color("LossRed"))
                }
            } header: {
                Text("Email")
            }

            Section {
                TextEditor(text: $message)
                    .frame(minHeight: 120)
                    .accessibilityLabel("Feedback message")
                    .onChange(of: message) { _, newValue in
                        if newValue.count > maxMessageLength {
                            message = String(newValue.prefix(maxMessageLength))
                        }
                    }
                HStack {
                    Spacer()
                    Text("\(message.count) / \(maxMessageLength)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Message")
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Submit")
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(!canSubmit || isSubmitting)
                .listRowBackground(canSubmit && !isSubmitting ? Color.accentColor : Color.gray.opacity(0.3))
                .foregroundStyle(.white)
                .accessibilityLabel("Submit feedback")

                Text("We only use your email to respond to this feedback.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)

                if let result {
                    Label(result.text, systemImage: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(result.success ? Color("ProfitGreen") : Color("LossRed"))
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func subjectTile(_ item: Subject) -> some View {
        let isSelected = subject == item
        return Button {
            subject = item
        } label: {
            VStack(spacing: 6) {
                HStack {
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 12)
                Image(systemName: item.icon)
                    .font(.title3)
                Text(item.rawValue)
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? Color.white : Color.secondary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.accentColor : Color(.separator), lineWidth: 1)
            )
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.snappy(duration: 0.2), value: subject)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Subject: \(item.rawValue)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func submit() async {
        isSubmitting = true
        result = nil
        let finalSubject = subject == .other ? customSubject : subject.rawValue
        let body = FeedbackRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            subject: finalSubject,
            message: message.trimmingCharacters(in: .whitespaces),
            app_name: "ProfitPaw"
        )
        do {
            var request = URLRequest(url: URL(string: "https://msg.calcs.top/api/feedback")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30
            request.httpBody = try JSONEncoder().encode(body)
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status == 200,
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               obj["success"] as? Bool == true {
                result = SubmitResult(success: true, text: "Thank you! Your feedback has been sent.")
                message = ""
            } else {
                let serverError = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
                result = SubmitResult(success: false, text: serverError ?? "Something went wrong. Please try again.")
            }
        } catch {
            result = SubmitResult(success: false, text: "Network error. Please check your connection and try again.")
        }
        isSubmitting = false
    }
}

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}
