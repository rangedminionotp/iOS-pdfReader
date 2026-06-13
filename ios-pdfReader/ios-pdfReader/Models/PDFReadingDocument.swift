import Foundation

struct PDFReadingDocument {
    let pages: [PDFReadingPage]

    var isEmpty: Bool {
        pages.allSatisfy { $0.blocks.isEmpty }
    }

    nonisolated static let empty = PDFReadingDocument(pages: [])
}

struct PDFReadingPage: Identifiable {
    let number: Int
    let blocks: [PDFReadingBlock]

    var id: Int { number }
}

struct PDFReadingBlock: Identifiable {
    enum Kind {
        case heading(text: String, level: Int)
        case paragraph(String)
        case list(items: [String], ordered: Bool)
        case note(String)
    }

    let id = UUID()
    let kind: Kind
}
