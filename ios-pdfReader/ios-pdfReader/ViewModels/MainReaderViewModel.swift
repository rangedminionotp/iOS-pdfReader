import Combine
import PDFKit
import SwiftUI

@MainActor
final class MainReaderViewModel: ObservableObject {
    enum ReaderMode: String, CaseIterable, Identifiable {
        case pdf = "PDF"
        case text = "Text"

        var id: String { rawValue }
    }

    @Published private(set) var document: PDFDocument?
    @Published var errorMessage: String?
    @Published var readerMode: ReaderMode = .pdf
    @Published var textSize: CGFloat = 20
    @Published private(set) var extractedText = ""
    @Published private(set) var isLoading = false
    @Published private(set) var isPreparingText = false

    private let documentImporter: PDFDocumentImporting
    private var documentData: Data?

    init(documentImporter: PDFDocumentImporting? = nil) {
        self.documentImporter = documentImporter ?? PDFDocumentImporter()
    }

    func openDocument(at url: URL) async {
        isLoading = true
        do {
            let loadedPDF = try await documentImporter.loadDocument(from: url)
            document = loadedPDF.document
            documentData = loadedPDF.data
            extractedText = ""
            readerMode = .pdf
            textSize = 20
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func closeDocument() {
        document = nil
        documentData = nil
        extractedText = ""
        readerMode = .pdf
        textSize = 20
        isPreparingText = false
    }

    func clearError() {
        errorMessage = nil
    }

    func setError(_ message: String) {
        errorMessage = message
    }

    func makeTextSmaller() {
        textSize = max(14, textSize - 2)
    }

    func makeTextLarger() {
        textSize = min(34, textSize + 2)
    }

    func resetTextSize() {
        textSize = 20
    }

    func selectMode(_ mode: ReaderMode) async {
        guard mode != .pdf else {
            readerMode = .pdf
            return
        }

        guard let documentData else {
            return
        }

        if !extractedText.isEmpty {
            readerMode = .text
            return
        }

        isPreparingText = true
        let extracted = await PDFDocumentImporter.extractText(from: documentData)
        extractedText = extracted
        readerMode = .text
        isPreparingText = false
    }
}
