import SwiftUI

struct PageIndexSheetView: View {
    let pageCount: Int
    let currentPage: Int
    let onSelectPage: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(1...pageCount, id: \.self) { page in
                Button {
                    onSelectPage(page)
                    dismiss()
                } label: {
                    HStack {
                        Text("Page \(page)")
                            .foregroundStyle(.primary)

                        Spacer()

                        if page == currentPage {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
