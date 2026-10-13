import Foundation
import SwiftUI
import PhotosUI

@MainActor
final class InvoiceScanViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var items: [InvoiceItem] = []
    @Published var errorMessage: String?
    @Published var source: String?
    @Published var lastResultDate: Date?

    func process(data: Data) async {
        isProcessing = true
        errorMessage = nil
        items = []
        defer { isProcessing = false }
        let base64 = data.base64EncodedString()
        do {
            let result = try await AIService.scanInvoice(imageBase64: base64)
            items = result.items
            source = result.source.rawValue
            lastResultDate = Date()
            InvoiceScanResult.save(InvoiceScanResult(date: Date(), items: result.items))
            AppSettings.incrementInvoiceScans()
        } catch let error as CloudError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not read this image. Try a clearer photo."
        }
    }
}
