import PDFKit
import SwiftUI
import UIKit

struct PDFReaderView: UIViewRepresentable {
    let document: PDFDocument
    let zoomLevel: Double
    @Binding var currentPage: Int
    @Binding var targetPage: Int?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true)
        pdfView.backgroundColor = UIColor(red: 0.94, green: 0.91, blue: 0.82, alpha: 1.0)
        pdfView.document = document
        pdfView.pageShadowsEnabled = false
        context.coordinator.parent = self

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageDidChange(_:)),
            name: Notification.Name.PDFViewPageChanged,
            object: pdfView
        )

        if let scrollView = pdfView.subviews.compactMap({ $0 as? UIScrollView }).first {
            scrollView.backgroundColor = UIColor(red: 0.96, green: 0.94, blue: 0.86, alpha: 1.0)
        }

        DispatchQueue.main.async {
            let fittedScale = max(pdfView.scaleFactorForSizeToFit, 0.1)
            context.coordinator.baseScaleFactor = fittedScale
            applyZoom(to: pdfView, coordinator: context.coordinator)
            applyReaderAppearance(to: pdfView)
        }
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        context.coordinator.parent = self

        if pdfView.document !== document {
            pdfView.document = document
            pdfView.goToFirstPage(nil)
            pdfView.autoScales = true
            DispatchQueue.main.async {
                let fittedScale = max(pdfView.scaleFactorForSizeToFit, 0.1)
                context.coordinator.baseScaleFactor = fittedScale
                applyZoom(to: pdfView, coordinator: context.coordinator)
                applyReaderAppearance(to: pdfView)
            }
            return
        }

        if let targetPage,
           targetPage != context.coordinator.lastNavigatedPage,
           let page = document.page(at: targetPage - 1) {
            context.coordinator.lastNavigatedPage = targetPage
            pdfView.go(to: page)
        }

        applyZoom(to: pdfView, coordinator: context.coordinator)
        applyReaderAppearance(to: pdfView)
    }

    private func applyZoom(to pdfView: PDFView, coordinator: Coordinator) {
        let baseScaleFactor = max(coordinator.baseScaleFactor, 0.1)
        pdfView.minScaleFactor = baseScaleFactor * 0.5
        pdfView.maxScaleFactor = baseScaleFactor * 3.0
        pdfView.scaleFactor = baseScaleFactor * zoomLevel
    }

    private func applyReaderAppearance(to pdfView: PDFView) {
        pdfView.backgroundColor = UIColor(red: 0.94, green: 0.91, blue: 0.82, alpha: 1.0)

        if let scrollView = pdfView.subviews.compactMap({ $0 as? UIScrollView }).first {
            scrollView.backgroundColor = UIColor(red: 0.96, green: 0.94, blue: 0.86, alpha: 1.0)
        }

        pdfView.documentView?.subviews.forEach { pageView in
            pageView.backgroundColor = UIColor(red: 0.99, green: 0.97, blue: 0.90, alpha: 1.0)
        }
    }

    final class Coordinator: NSObject {
        var parent: PDFReaderView?
        var baseScaleFactor = 1.0
        var lastNavigatedPage: Int?

        @objc func pageDidChange(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let page = pdfView.currentPage,
                  let document = pdfView.document else {
                return
            }

            let pageNumber = document.index(for: page) + 1
            lastNavigatedPage = pageNumber

            DispatchQueue.main.async { [weak self] in
                self?.parent?.currentPage = pageNumber
                self?.parent?.targetPage = nil
            }
        }
    }
}
