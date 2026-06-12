import SwiftUI

struct PDFTextReaderView: View {
    let text: String
    let textSize: CGFloat

    var body: some View {
        Group {
            if text.isEmpty {
                ContentUnavailableView(
                    "No Extractable Text",
                    systemImage: "text.page.slash",
                    description: Text("This PDF appears to be scanned or image-based, so text-reading mode is unavailable.")
                )
            } else {
                ScrollView {
                    Text(text)
                        .font(.system(size: textSize, weight: .regular, design: .serif))
                        .foregroundStyle(Color(red: 0.22, green: 0.18, blue: 0.12))
                        .lineSpacing(textSize * 0.45)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24)
                }
                .background(Color(red: 0.97, green: 0.95, blue: 0.88))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.94, green: 0.91, blue: 0.82))
    }
}
