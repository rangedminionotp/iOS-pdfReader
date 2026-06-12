import Combine
import PDFKit
import SwiftUI

@MainActor
final class MainReaderViewModel: ObservableObject {
    @Published private(set) var document: PDFDocument?
    @Published var errorMessage: String?

    private let documentImporter: PDFDocumentImporting

    init(documentImporter: PDFDocumentImporting? = nil) {
        self.documentImporter = documentImporter ?? PDFDocumentImporter()
    }

    func openDocument(at url: URL) async {
        do {
            document = try documentImporter.loadDocument(from: url)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func closeDocument() {
        document = nil
    }

    func clearError() {
        errorMessage = nil
    }

    func setError(_ message: String) {
        errorMessage = message
    }
}
