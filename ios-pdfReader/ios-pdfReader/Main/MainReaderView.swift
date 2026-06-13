import SwiftUI
import UniformTypeIdentifiers

struct MainReaderView: View {
    @StateObject private var viewModel = MainReaderViewModel()
    @State private var isShowingDocumentPicker = false
    @State private var isShowingPageIndex = false

    var body: some View {
        NavigationStack {
            Group {
                if let document = viewModel.document {
                    if viewModel.isPreparingText {
                        ProgressView("Preparing text...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.readerMode == .pdf {
                        PDFReaderView(
                            document: document,
                            zoomLevel: 1.0,
                            currentPage: $viewModel.currentPage,
                            targetPage: $viewModel.targetPage
                        )
                            .ignoresSafeArea(edges: .bottom)
                    } else {
                        PDFTextReaderView(
                            pages: viewModel.textPages,
                            textSize: viewModel.textSize,
                            currentPage: $viewModel.currentPage,
                            targetPage: $viewModel.targetPage
                        )
                    }
                } else {
                    EmptyReaderView(isLoading: viewModel.isLoading)
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

                ToolbarItem(placement: .principal) {
                    if viewModel.document != nil {
                        ReaderModePickerView(
                            selection: viewModel.readerMode,
                            onSelect: { mode in
                                Task {
                                    await viewModel.selectMode(mode)
                                }
                            }
                        )
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if viewModel.document != nil {
                            Button {
                                isShowingPageIndex = true
                            } label: {
                                Label("Pages", systemImage: "list.bullet.rectangle")
                            }
                        }

                        if viewModel.document != nil && viewModel.readerMode == .text {
                            TextSizeControlsView(
                                textSize: viewModel.textSize,
                                onDecrease: viewModel.makeTextSmaller,
                                onReset: viewModel.resetTextSize,
                                onIncrease: viewModel.makeTextLarger
                            )
                        }

                        Button {
                            isShowingDocumentPicker = true
                        } label: {
                            Label(viewModel.document == nil ? "Open PDF" : "Change PDF", systemImage: "folder")
                        }
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
            .sheet(isPresented: $isShowingPageIndex) {
                PageIndexSheetView(
                    pageCount: viewModel.pageCount,
                    currentPage: viewModel.currentPage,
                    onSelectPage: { page in
                        viewModel.jumpToPage(page)
                    }
                )
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
