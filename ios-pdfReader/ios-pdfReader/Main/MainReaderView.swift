//
/**
 * © 2019 - 2025 SEG Solutions
 *
 * NOTICE: All information contained herein is, and remains
 * the property of SEG Solutions and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to SEG Solutions and its suppliers.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from SEG Solutions.
 */

import Foundation
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct MainReaderView: View {
    @State private var isShowingDocumentPicker = false
    @State private var document: PDFDocument?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if let document {
                    PDFReaderView(document: document, zoomLevel: 1.0)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    ContentUnavailableView(
                        "No PDF Open",
                        systemImage: "doc.richtext",
                        description: Text("Choose a PDF from Files to start reading.")
                    )
                }
            }
            .navigationTitle("PDF Reader")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if document != nil {
                        Button("Close") {
                            closeDocument()
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingDocumentPicker = true
                    } label: {
                        Label(document == nil ? "Open PDF" : "Change PDF", systemImage: "folder")
                    }
                }
            }
            .alert("Unable to Open PDF", isPresented: isShowingError) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "Please try another file.")
            }
            .fileImporter(
                isPresented: $isShowingDocumentPicker,
                allowedContentTypes: [.pdf]
            ) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let url):
                        openDocument(at: url)
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { newValue in
                if !newValue {
                    errorMessage = nil
                }
            }
        )
    }

    private func openDocument(at url: URL) {
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let importedURL: URL

        do {
            importedURL = try importDocument(from: url)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        guard let documentData = try? Data(contentsOf: importedURL),
              let document = PDFDocument(data: documentData),
              document.pageCount > 0 else {
            errorMessage = "The selected file could not be loaded as a PDF."
            return
        }

        self.document = document
    }

    private func closeDocument() {
        document = nil
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

private enum PDFImportError: LocalizedError {
    case importFailed

    var errorDescription: String? {
        switch self {
        case .importFailed:
            return "The selected PDF could not be imported into the app."
        }
    }
}
