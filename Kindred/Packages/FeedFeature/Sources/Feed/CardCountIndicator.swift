import DesignSystem
import SwiftUI

struct CardCountIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        Text("\(current) of \(total)")
            .font(.kindredCaption())
            .foregroundColor(.kindredTextSecondary)
    }
}
