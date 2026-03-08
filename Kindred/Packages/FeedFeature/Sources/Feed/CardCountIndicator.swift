import DesignSystem
import SwiftUI

struct CardCountIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        Text(String(localized: "\(current) of \(total)"))
            .font(.kindredCaption())
            .foregroundColor(.kindredTextSecondary)
    }
}
