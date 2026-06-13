import Foundation

struct PDFTextPage: Identifiable, Equatable {
    let pageNumber: Int
    let text: String

    var id: Int { pageNumber }
}
