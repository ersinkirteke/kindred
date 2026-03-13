import SwiftUI
import UIKit

/// Expandable floating action button with "Add manually", "Scan items", and "Scan receipt" options
struct ExpandableFAB: View {
    @Binding var isExpanded: Bool
    let onAddManual: () -> Void
    let onScanItems: () -> Void
    let onScanReceipt: (() -> Void)?
    let showProBadge: Bool

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(spacing: 16) {
            // Secondary buttons (shown when expanded)
            if isExpanded {
                if let onScanReceipt = onScanReceipt {
                    secondaryButton(
                        title: String(localized: "scan.receipt.fab_label", defaultValue: "Scan receipt", bundle: .main),
                        icon: "doc.text.viewfinder",
                        showBadge: showProBadge,
                        action: onScanReceipt
                    )
                }

                secondaryButton(
                    title: String(localized: "pantry.fab.scan_items", defaultValue: "Scan items", bundle: .main),
                    icon: "camera.fill",
                    showBadge: showProBadge,
                    action: onScanItems
                )

                secondaryButton(
                    title: String(localized: "pantry.fab.add_manually", defaultValue: "Add manually", bundle: .main),
                    icon: "plus",
                    showBadge: false,
                    action: onAddManual
                )
            }

            // Primary button (always visible)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                if isExpanded {
                    feedbackGenerator.impactOccurred()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor, in: Circle())
                    .shadow(radius: 4, y: 2)
            }
            .accessibilityLabel(isExpanded
                ? String(localized: "pantry.fab.close", defaultValue: "Close menu", bundle: .main)
                : String(localized: "pantry.fab.actions", defaultValue: "Pantry actions", bundle: .main)
            )
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func secondaryButton(title: String, icon: String, showBadge: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded = false
            }
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                if showBadge {
                    Text(String(localized: "pantry.fab.pro_badge", defaultValue: "Pro", bundle: .main))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2), in: Capsule())
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground), in: Capsule())
            .shadow(radius: 2, y: 1)
        }
        .transition(animationTransition)
        .accessibilityLabel(showBadge ? "\(title) (Pro feature)" : title)
    }

    private var animationTransition: AnyTransition {
        if UIAccessibility.isReduceMotionEnabled {
            return .opacity
        } else {
            return .scale.combined(with: .opacity)
        }
    }
}
