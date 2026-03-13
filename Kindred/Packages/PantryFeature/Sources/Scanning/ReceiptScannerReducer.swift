import ComposableArchitecture
import Foundation
import UIKit

@Reducer
public struct ReceiptScannerReducer {
    @ObservableState
    public struct State: Equatable {
        public var isScanning: Bool = true
        public var recognizedText: String = ""
        public var hasDetectedText: Bool = false

        public init() {}
    }

    public enum Action {
        case textRecognized(String)
        case captureReceiptTapped
        case cancelTapped
        case delegate(Delegate)
    }

    public enum Delegate: Equatable {
        case receiptTextCaptured(String)
        case cancelled
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .textRecognized(text):
                state.recognizedText = text

                // Trigger light haptic on first text detection
                if !state.hasDetectedText && !text.isEmpty {
                    state.hasDetectedText = true
                    return .run { _ in
                        await MainActor.run {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }

                return .none

            case .captureReceiptTapped:
                state.isScanning = false
                return .send(.delegate(.receiptTextCaptured(state.recognizedText)))

            case .cancelTapped:
                return .send(.delegate(.cancelled))

            case .delegate:
                return .none
            }
        }
    }
}
