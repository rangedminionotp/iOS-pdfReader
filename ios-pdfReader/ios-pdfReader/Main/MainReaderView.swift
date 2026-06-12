import SwiftUI
import UniformTypeIdentifiers

struct MainReaderView: View {
    @StateObject private var viewModel = MainReaderViewModel()
    @State private var isShowingDocumentPicker = false

    var body: some View {
        NavigationStack {
            Group {
                if let document = viewModel.document {
                    PDFReaderView(document: document, zoomLevel: 1.0)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    EmptyReaderView()
                }
            }
            .navigationTitle("PDF Reader")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.document != nil {
                        Button("Close") {
                            viewModel.closeDocument()
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingDocumentPicker = true
                    } label: {
                        Label(viewModel.document == nil ? "Open PDF" : "Change PDF", systemImage: "folder")
                    }
                }
            }
            .alert("Unable to Open PDF", isPresented: isShowingError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "Please try another file.")
            }
            .fileImporter(
                isPresented: $isShowingDocumentPicker,
                allowedContentTypes: [.pdf]
            ) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let url):
                        await viewModel.openDocument(at: url)
                    case .failure(let error):
                        viewModel.setError(error.localizedDescription)
                    }
                }
            }
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.clearError()
                }
            }
        )
    }
}
