import SwiftUI

// MARK: - OfflineBanner
// Consistent orange offline indicator for all screens
// Per accessibility decision: Shared component for consistent offline messaging

public struct OfflineBanner: View {

    // MARK: - Initializer

    public init() {}

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .medium))

            Text("You're offline")
                .font(.kindredCaption())
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.orange)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You're offline")
    }
}

// MARK: - Preview

#if DEBUG
struct OfflineBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            OfflineBanner()

            VStack {
                Text("Screen content below")
                    .font(.kindredBody())
                    .foregroundStyle(.kindredTextSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.kindredBackground)
        }
    }
}
#endif
