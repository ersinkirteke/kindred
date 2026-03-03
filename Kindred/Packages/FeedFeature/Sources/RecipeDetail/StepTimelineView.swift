import SwiftUI
import DesignSystem

// MARK: - Step Timeline View

struct StepTimelineView: View {

    let steps: [RecipeStep]
    var currentStepIndex: Int? = nil

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                ForEach(sortedSteps) { step in
                    StepRow(
                        step: step,
                        isLast: step.id == sortedSteps.last?.id,
                        isCurrentStep: currentStepIndex == step.orderIndex
                    )
                    .id(step.orderIndex)
                }
            }
            .onChange(of: currentStepIndex) { oldValue, newValue in
                if let newIndex = newValue {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
    }

    private var sortedSteps: [RecipeStep] {
        steps.sorted { $0.orderIndex < $1.orderIndex }
    }
}

// MARK: - Step Row

private struct StepRow: View {

    let step: RecipeStep
    let isLast: Bool
    var isCurrentStep: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: KindredSpacing.md) {
            // Timeline connector
            VStack(spacing: 0) {
                // Numbered circle
                ZStack {
                    Circle()
                        .fill(Color.kindredAccent)
                        .frame(width: 32, height: 32)
                        .shadow(color: isCurrentStep ? Color.kindredAccent.opacity(0.4) : .clear, radius: 8, x: 0, y: 0)

                    Text("\(step.orderIndex)")
                        .font(.kindredBodyBold())
                        .foregroundColor(.white)
                }

                // Connector line (except for last step)
                if !isLast {
                    Rectangle()
                        .fill(Color.kindredDivider)
                        .frame(width: 2)
                        .frame(minHeight: 40)
                }
            }

            // Step content
            VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                Text(step.text)
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextPrimary)
                    .multilineTextAlignment(.leading)

                // Duration badge if present
                if let duration = step.duration {
                    HStack(spacing: KindredSpacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("~\(duration) min")
                            .font(.kindredCaption())
                    }
                    .foregroundColor(.kindredTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, isLast ? 0 : KindredSpacing.lg)
            .padding(KindredSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrentStep ? Color.kindredAccent.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCurrentStep ? Color.kindredAccent : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stepAccessibilityLabel)
    }

    private var stepAccessibilityLabel: String {
        var label = isCurrentStep ? "Currently playing: Step \(step.orderIndex), " : "Step \(step.orderIndex), "
        label += step.text
        if let duration = step.duration {
            label += ", approximately \(duration) minutes"
        }
        return label
    }
}

// MARK: - Preview

#if DEBUG
struct StepTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        StepTimelineView(
            steps: [
                RecipeStep(orderIndex: 1, text: "Preheat oven to 350°F (175°C).", duration: 5, techniqueTag: nil),
                RecipeStep(orderIndex: 2, text: "In a large bowl, mix flour, sugar, and baking powder.", duration: 3, techniqueTag: "mixing"),
                RecipeStep(orderIndex: 3, text: "Add eggs and vanilla extract, mix until smooth.", duration: 2, techniqueTag: "mixing"),
                RecipeStep(orderIndex: 4, text: "Pour batter into greased pan and bake for 30 minutes.", duration: 30, techniqueTag: "baking")
            ]
        )
        .padding()
        .background(Color.kindredBackground)
    }
}
#endif
