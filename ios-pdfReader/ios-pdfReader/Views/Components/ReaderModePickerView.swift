import SwiftUI

struct ReaderModePickerView: View {
    let selection: MainReaderViewModel.ReaderMode
    let onSelect: (MainReaderViewModel.ReaderMode) -> Void

    var body: some View {
        Picker(
            "Reader Mode",
            selection: Binding(
                get: { selection },
                set: { onSelect($0) }
            )
        ) {
            ForEach(MainReaderViewModel.ReaderMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 180)
    }
}
