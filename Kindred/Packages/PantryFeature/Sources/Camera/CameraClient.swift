import AVFoundation
import Dependencies
import Foundation

/// TCA dependency for managing camera permissions and authorization status
public struct CameraClient {
    /// Request camera authorization with poll-based pattern (matches LocationClient)
    /// Checks current status, requests if notDetermined, then polls until authorization completes
    public var requestAuthorization: @Sendable () async -> AVAuthorizationStatus

    /// Get current camera authorization status synchronously
    public var authorizationStatus: @Sendable () -> AVAuthorizationStatus
}

extension CameraClient: DependencyKey {
    public static var liveValue: CameraClient {
        CameraClient(
            requestAuthorization: {
                let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)

                // If already determined, return immediately
                guard currentStatus == .notDetermined else {
                    return currentStatus
                }

                // Request permission on main thread
                await MainActor.run {
                    AVCaptureDevice.requestAccess(for: .video) { _ in }
                }

                // Poll for status change (max 30s, check every 500ms)
                let maxAttempts = 60 // 30 seconds / 500ms
                for _ in 0..<maxAttempts {
                    let status = AVCaptureDevice.authorizationStatus(for: .video)
                    if status != .notDetermined {
                        return status
                    }
                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
                }

                // Timeout - return current status
                return AVCaptureDevice.authorizationStatus(for: .video)
            },
            authorizationStatus: {
                AVCaptureDevice.authorizationStatus(for: .video)
            }
        )
    }

    public static var testValue: CameraClient {
        CameraClient(
            requestAuthorization: { .authorized },
            authorizationStatus: { .authorized }
        )
    }
}

extension DependencyValues {
    public var cameraClient: CameraClient {
        get { self[CameraClient.self] }
        set { self[CameraClient.self] = newValue }
    }
}
