import PDFKit
import SwiftUI
import UIKit

struct PDFReaderView: UIViewRepresentable {
    let document: PDFDocument
    let zoomLevel: Double

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

    final class Coordinator {
        var baseScaleFactor = 1.0
    }
}
