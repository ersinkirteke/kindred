import ComposableArchitecture
import SwiftUI
import VisionKit

public struct ReceiptScannerView: View {
    let store: StoreOf<ReceiptScannerReducer>

    public init(store: StoreOf<ReceiptScannerReducer>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .bottom) {
                // VisionKit DataScanner
                DataScannerViewControllerRepresentable(store: store)
                    .ignoresSafeArea()

                // Overlay controls
                VStack(spacing: 0) {
                    Spacer()

                    // Text detected indicator
                    if !store.recognizedText.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)

                            Text(String(localized: "scan.receipt.text_detected", bundle: .main))
                                .font(.subheadline.bold())
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 12)
                    }

                    // Bottom bar with buttons
                    HStack(spacing: 16) {
                        Button {
                            store.send(.cancelTapped)
                        } label: {
                            Text(String(localized: "scan.receipt.cancel", bundle: .main))
                                .font(.body.bold())
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(.regularMaterial)
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            store.send(.captureReceiptTapped)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")

                                Text(String(localized: "scan.receipt.capture", bundle: .main))
                                    .font(.body.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(store.recognizedText.isEmpty)
                        .accessibilityLabel(String(localized: "scan.receipt.capture", bundle: .main))
                        .accessibilityHint(store.recognizedText.isEmpty ? String(localized: "scan.receipt.position_receipt", bundle: .main) : "")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - DataScannerViewController Wrapper

struct DataScannerViewControllerRepresentable: UIViewControllerRepresentable {
    let store: StoreOf<ReceiptScannerReducer>

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType> = [.text()]
        let viewController = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )

        viewController.delegate = context.coordinator

        return viewController
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Start scanning if needed
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let store: StoreOf<ReceiptScannerReducer>

        init(store: StoreOf<ReceiptScannerReducer>) {
            self.store = store
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Accumulate all recognized text
            let allText = allItems
                .compactMap { item -> String? in
                    guard case .text(let text) = item else { return nil }
                    return text.transcript
                }
                .joined(separator: "\n")

            store.send(.textRecognized(allText))
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Accumulate all recognized text
            let allText = allItems
                .compactMap { item -> String? in
                    guard case .text(let text) = item else { return nil }
                    return text.transcript
                }
                .joined(separator: "\n")

            store.send(.textRecognized(allText))
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Accumulate all recognized text
            let allText = allItems
                .compactMap { item -> String? in
                    guard case .text(let text) = item else { return nil }
                    return text.transcript
                }
                .joined(separator: "\n")

            store.send(.textRecognized(allText))
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            // Optional: handle tap on recognized item
        }
    }
}
