import Foundation

/// Errors that can occur during camera operations
public enum CameraError: Error, LocalizedError {
    case noCameraAvailable
    case captureSessionFailed
    case imageProcessingFailed
    case permissionDenied
    case compressionFailed
    case uploadFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noCameraAvailable:
            return "No camera is available on this device."
        case .captureSessionFailed:
            return "Failed to start the camera session."
        case .imageProcessingFailed:
            return "Failed to process the captured image."
        case .permissionDenied:
            return "Camera permission was denied. Please enable it in Settings."
        case .compressionFailed:
            return "Failed to compress the captured image."
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        }
    }
}
