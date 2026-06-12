import SwiftUI

struct EmptyReaderView: View {
    let isLoading: Bool

    var body: some View {
        if isLoading {
            ProgressView("Loading PDF...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ContentUnavailableView(
                "No PDF Open",
                systemImage: "doc.richtext",
                description: Text("Choose a PDF from Files to start reading.")
            )
        }
    }
}
