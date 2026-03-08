import DesignSystem
import SwiftUI

struct DietaryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : .kindredAccent)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 44) // Ensure 44pt tappable height
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.kindredAccent : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.kindredAccent, lineWidth: isSelected ? 0 : 1.5)
                    )
            )
            .onTapGesture(perform: onTap)
            .accessibilityLabel(String(localized: "\(title) filter", bundle: .main))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(String(localized: "accessibility.dietary_chip.toggle_hint", bundle: .main))
    }
}
