import SwiftUI

struct TextSizeControlsView: View {
    let textSize: CGFloat
    let onDecrease: () -> Void
    let onReset: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onDecrease) {
                Image(systemName: "textformat.size.smaller")
            }
            .accessibilityLabel("Make text smaller")

            Button("\(Int(textSize))") {
                onReset()
            }
            .font(.caption.weight(.semibold))

            Button(action: onIncrease) {
                Image(systemName: "textformat.size.larger")
            }
            .accessibilityLabel("Make text larger")
        }
    }
}
