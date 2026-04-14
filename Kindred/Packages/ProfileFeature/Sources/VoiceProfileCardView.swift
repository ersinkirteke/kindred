import DesignSystem
import SwiftUI

struct VoiceProfileCardView: View {
    let profile: VoiceProfileInfo
    let isDeleting: Bool
    let onDelete: () -> Void

    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 16
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 12

    var body: some View {
        HStack(spacing: KindredSpacing.md) {
            // Avatar circle with waveform icon
            ZStack {
                Circle()
                    .fill(Color.kindredAccent.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: "waveform")
                    .font(.system(size: 20))
                    .foregroundStyle(.kindredAccent)
            }

            // Voice info
            VStack(alignment: .leading, spacing: KindredSpacing.xs) {
                Text(profile.speakerName)
                    .font(.kindredBodyBoldScaled(size: bodySize))
                    .foregroundStyle(.kindredTextPrimary)

                Text(profile.relationship)
                    .font(.kindredCaptionScaled(size: captionSize))
                    .foregroundStyle(.kindredTextSecondary)

                Text(String(localized: "profile.voice_profile.created \(formattedDate)", bundle: .main))
                    .font(.kindredCaptionScaled(size: captionSize))
                    .foregroundStyle(.kindredTextSecondary)

                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)

                    Text(statusText)
                        .font(.kindredCaptionScaled(size: captionSize))
                        .foregroundStyle(.kindredTextSecondary)
                }
            }

            Spacer()

            // Delete button or spinner
            if isDeleting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .kindredAccent))
            } else {
                Button {
                    onDelete()
                } label: {
                    Text(String(localized: "profile.privacy_data.delete_voice", bundle: .main))
                        .font(.kindredBodyScaled(size: bodySize))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(KindredSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.kindredCardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.kindredDivider, lineWidth: 1)
        )
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private var formattedDate: String {
        Self.dateFormatter.string(from: profile.createdAt)
    }

    private var statusColor: Color {
        switch profile.status {
        case .ready:
            return .green
        case .processing:
            return .orange
        case .failed:
            return .red
        }
    }

    private var statusText: String {
        switch profile.status {
        case .ready:
            return String(localized: "voice.status.ready", bundle: .main)
        case .processing:
            return String(localized: "voice.status.processing", bundle: .main)
        case .failed:
            return String(localized: "voice.status.failed", bundle: .main)
        }
    }
}
