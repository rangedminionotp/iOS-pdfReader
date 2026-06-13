import SwiftUI

struct PDFTextReaderView: View {
    let pages: [PDFTextPage]
    let textSize: CGFloat
    @Binding var currentPage: Int
    @Binding var targetPage: Int?

    var body: some View {
        Group {
            if pages.isEmpty {
                ContentUnavailableView(
                    "No Extractable Text",
                    systemImage: "text.page.slash",
                    description: Text("This PDF appears to be scanned or image-based, so text-reading mode is unavailable.")
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(pages) { page in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Page \(page.pageNumber)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color(red: 0.47, green: 0.37, blue: 0.22))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color(red: 0.91, green: 0.86, blue: 0.73))
                                        )

                                    Text(page.text)
                                        .font(.system(size: textSize, weight: .regular, design: .serif))
                                        .foregroundStyle(Color(red: 0.22, green: 0.18, blue: 0.12))
                                        .lineSpacing(textSize * 0.45)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .textSelection(.enabled)
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(Color(red: 0.99, green: 0.97, blue: 0.91))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color(red: 0.90, green: 0.85, blue: 0.72), lineWidth: 1)
                                )
                                .id(page.pageNumber)
                                .onAppear {
                                    currentPage = page.pageNumber
                                }
                            }
                        }
                        .padding(20)
                    }
                    .onChange(of: targetPage) { _, newValue in
                        guard let newValue else {
                            return
                        }

                        withAnimation {
                            proxy.scrollTo(newValue, anchor: .top)
                        }

                        currentPage = newValue
                        targetPage = nil
                    }
                }
                .background(Color(red: 0.97, green: 0.95, blue: 0.88))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.94, green: 0.91, blue: 0.82))
    }
}
