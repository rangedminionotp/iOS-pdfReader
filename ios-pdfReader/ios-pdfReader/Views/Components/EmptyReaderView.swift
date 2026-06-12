import SwiftUI

struct EmptyReaderView: View {
    var body: some View {
        ContentUnavailableView(
            "No PDF Open",
            systemImage: "doc.richtext",
            description: Text("Choose a PDF from Files to start reading.")
        )
    }
}
