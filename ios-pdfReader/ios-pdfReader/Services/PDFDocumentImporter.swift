import Foundation
import PDFKit

struct LoadedPDF {
    let document: PDFDocument
    let data: Data
}

protocol PDFDocumentImporting {
    func loadDocument(from sourceURL: URL) async throws -> LoadedPDF
}

struct PDFDocumentImporter: PDFDocumentImporting {
    func loadDocument(from sourceURL: URL) async throws -> LoadedPDF {
        let task = Task.detached(priority: .userInitiated) {
            let shouldStopAccessing = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if shouldStopAccessing {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            let importedURL = try Self.importDocument(from: sourceURL)

            guard let documentData = try? Data(contentsOf: importedURL, options: .mappedIfSafe),
                  let document = PDFDocument(data: documentData),
                  document.pageCount > 0 else {
                throw PDFImportError.invalidPDF
            }

            return LoadedPDF(document: document, data: documentData)
        }

        return try await task.value
    }

    static func extractText(from documentData: Data) async -> String {
        await Task.detached(priority: .utility) {
            guard let document = PDFDocument(data: documentData) else {
                return ""
            }

            let pageTexts = (0..<document.pageCount).compactMap { index -> String? in
                guard let page = document.page(at: index) else {
                    return nil
                }

                let pageText = page.string?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                guard !pageText.isEmpty else {
                    return nil
                }

                return "Page \(index + 1)\n\(pageText)"
            }

            return pageTexts.joined(separator: "\n\n")
        }.value
    }

    private static func importDocument(from sourceURL: URL) throws -> URL {
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
            let documentData = try Data(contentsOf: sourceURL, options: .mappedIfSafe)
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
