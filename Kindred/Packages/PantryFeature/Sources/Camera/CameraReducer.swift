import ComposableArchitecture
import Foundation
import UIKit

@Reducer
public struct CameraReducer {
    @ObservableState
    public struct State: Equatable {
        public var capturedImage: UIImage? = nil
        public var flashMode: FlashMode = .auto
        public var zoomFactor: CGFloat = 1.0
        public var showHint: Bool = true
        public var isCapturing: Bool = false
        public var lastCaptureTime: Date? = nil
        public var showBlurWarning: Bool = false
        public var showPhotoPreview: Bool = false
        public var showClassification: Bool = false
        public var selectedScanType: ScanType? = nil
        public var isLowLight: Bool = false
        public var error: String? = nil

        public init() {}
    }

    public enum FlashMode: Equatable {
        case auto
        case on
        case off

        var iconName: String {
            switch self {
            case .auto:
                return "bolt.badge.automatic.fill"
            case .on:
                return "bolt.fill"
            case .off:
                return "bolt.slash.fill"
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .auto:
                return String(localized: "camera.flash.auto", defaultValue: "Flash: Auto", bundle: .main)
            case .on:
                return String(localized: "camera.flash.on", defaultValue: "Flash: On", bundle: .main)
            case .off:
                return String(localized: "camera.flash.off", defaultValue: "Flash: Off", bundle: .main)
            }
        }
    }

    public enum Action {
        case onAppear
        case hideHint
        case captureButtonTapped
        case photoCaptured(UIImage)
        case captureFailed(String)
        case retakeTapped
        case usePhotoTapped
        case scanTypeSelected(ScanType)
        case classificationDismissed
        case toggleFlash
        case zoomChanged(CGFloat)
        case blurDetectionResult(Bool)
        case blurWarningDismissed
        case blurWarningRetake
        case closeTapped
        case delegate(Delegate)

        public enum Delegate {
            case dismissed
            case photoReady(UIImage, ScanType)
        }
    }

    @Dependency(\.continuousClock) var clock

    private enum CancelID { case hintTimer }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Start 3-second hint timer
                return .run { send in
                    try await clock.sleep(for: .seconds(3))
                    await send(.hideHint)
                }
                .cancellable(id: CancelID.hintTimer)

            case .hideHint:
                state.showHint = false
                return .none

            case .captureButtonTapped:
                // 1-second debounce check
                if let lastCapture = state.lastCaptureTime,
                   Date().timeIntervalSince(lastCapture) < 1.0 {
                    return .none
                }

                state.isCapturing = true
                state.lastCaptureTime = Date()

                // Capture will be handled by view calling CameraManager.capturePhoto()
                return .none

            case let .photoCaptured(image):
                state.isCapturing = false
                state.capturedImage = image
                state.showPhotoPreview = true

                // Run blur detection
                return .run { send in
                    let isSharp = await Task.detached {
                        image.calculateSharpness().map { $0 >= 100 } ?? true
                    }.value
                    await send(.blurDetectionResult(!isSharp))
                }

            case let .captureFailed(errorMessage):
                state.isCapturing = false
                state.error = errorMessage
                return .none

            case .retakeTapped:
                state.capturedImage = nil
                state.showPhotoPreview = false
                state.showBlurWarning = false
                state.showClassification = false
                state.selectedScanType = nil
                return .none

            case .usePhotoTapped:
                state.showClassification = true
                return .none

            case let .scanTypeSelected(scanType):
                state.selectedScanType = scanType
                state.showClassification = false

                // Notify delegate with captured image and scan type
                if let image = state.capturedImage {
                    return .send(.delegate(.photoReady(image, scanType)))
                }
                return .none

            case .classificationDismissed:
                state.showClassification = false
                return .none

            case .toggleFlash:
                switch state.flashMode {
                case .auto:
                    state.flashMode = .on
                case .on:
                    state.flashMode = .off
                case .off:
                    state.flashMode = .auto
                }
                return .none

            case let .zoomChanged(factor):
                state.zoomFactor = factor
                return .none

            case let .blurDetectionResult(isBlurry):
                if isBlurry {
                    state.showBlurWarning = true
                }
                return .none

            case .blurWarningDismissed:
                state.showBlurWarning = false
                return .none

            case .blurWarningRetake:
                state.showBlurWarning = false
                return .send(.retakeTapped)

            case .closeTapped:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
    }
}
