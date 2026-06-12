import Foundation
import PDFKit

protocol PDFDocumentImporting {
    func loadDocument(from sourceURL: URL) throws -> PDFDocument
}

struct PDFDocumentImporter: PDFDocumentImporting {
    func loadDocument(from sourceURL: URL) throws -> PDFDocument {
        let shouldStopAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let importedURL = try importDocument(from: sourceURL)

        guard let documentData = try? Data(contentsOf: importedURL),
              let document = PDFDocument(data: documentData),
              document.pageCount > 0 else {
            throw PDFImportError.invalidPDF
        }

        return document
    }

    private func importDocument(from sourceURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let documentsDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let importDirectory = documentsDirectory.appendingPathComponent("ImportedPDFs", isDirectory: true)
        try fileManager.createDirectory(at: importDirectory, withIntermediateDirectories: true)

        let sanitizedName = sourceURL.lastPathComponent.isEmpty ? "Document.pdf" : sourceURL.lastPathComponent
        let destinationURL = importDirectory.appendingPathComponent("\(UUID().uuidString)-\(sanitizedName)")

        do {
            let documentData = try Data(contentsOf: sourceURL)
            try documentData.write(to: destinationURL, options: .atomic)
            return destinationURL
        } catch {
            throw PDFImportError.importFailed
        }
    }
}

enum PDFImportError: LocalizedError {
    case importFailed
    case invalidPDF

    var errorDescription: String? {
        switch self {
        case .importFailed:
            return "The selected PDF could not be imported into the app."
        case .invalidPDF:
            return "The selected file could not be loaded as a PDF."
        }
    }
}
