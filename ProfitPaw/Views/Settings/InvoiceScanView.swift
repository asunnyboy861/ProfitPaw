import SwiftUI
import PhotosUI

struct InvoiceScanView: View {
    @StateObject private var viewModel = InvoiceScanViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                quotaBadge
                if viewModel.isProcessing {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Reading your invoice...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else if !viewModel.items.isEmpty {
                    resultsCard
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Color("LossRed"))
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                } else {
                    pickers
                    infoCard
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Scan Invoice")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await viewModel.process(data: data)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in
                Task { await viewModel.process(data: data) }
            }
            .ignoresSafeArea()
        }
    }

    private var quotaBadge: some View {
        HStack {
            Image(systemName: "sparkles")
            Text("AI scans used this month: \(AppSettings.invoiceScansThisMonth())")
                .font(.footnote.weight(.medium))
            Spacer()
            Text("Plan quota applies on the server")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.accentColor.opacity(0.1), in: Capsule())
    }

    private var pickers: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Choose invoice photo from library")
            Button {
                showCamera = true
            } label: {
                Label("Take Photo", systemImage: "camera")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(Color.accentColor)
            }
            .accessibilityLabel("Take invoice photo with camera")
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How it works")
                .font(.headline)
            Label("Photograph a supplier invoice", systemImage: "1.circle")
            Label("AI extracts item names, unit costs and quantities", systemImage: "2.circle")
            Label("Review the extracted costs here", systemImage: "3.circle")
            Label("Finish on the web dashboard to save COGS to your store", systemImage: "4.circle")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var resultsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Extracted items")
                    .font(.headline)
                Spacer()
                if let source = viewModel.source {
                    Text("via \(source)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            ForEach(Array(viewModel.items.enumerated()), id: \.offset) { _, item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.itemDescription).font(.subheadline.weight(.medium))
                        if !item.skuGuess.isEmpty {
                            Text("SKU guess: \(item.skuGuess)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(item.currency) \(item.unitCost)")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                        Text("×\(item.qty)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
            Divider()
            Text("iOS stays read-only — open the web dashboard to write these costs into your store.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.7) {
                parent.onCapture(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
