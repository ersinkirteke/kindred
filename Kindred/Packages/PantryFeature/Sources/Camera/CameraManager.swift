import AVFoundation
import Combine
import UIKit

/// Manages AVCaptureSession for camera capture operations
/// All session operations dispatched to dedicated sessionQueue to avoid blocking main thread
final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.kindred.camera.session")
    private let output = AVCapturePhotoOutput()
    private var photoContinuation: CheckedContinuation<UIImage, Error>?
    private var device: AVCaptureDevice?

    @Published var currentZoomFactor: CGFloat = 1.0
    @Published var flashMode: AVCaptureDevice.FlashMode = .auto

    /// Setup camera session with rear camera input and photo output
    func setup() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.captureSessionFailed)
                    return
                }

                self.session.beginConfiguration()
                defer { self.session.commitConfiguration() }

                // Set session preset to photo quality
                self.session.sessionPreset = .photo

                // Get rear camera device
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    continuation.resume(throwing: CameraError.noCameraAvailable)
                    return
                }
                self.device = device

                // Add camera input
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if self.session.canAddInput(input) {
                        self.session.addInput(input)
                    } else {
                        continuation.resume(throwing: CameraError.captureSessionFailed)
                        return
                    }
                } catch {
                    continuation.resume(throwing: CameraError.captureSessionFailed)
                    return
                }

                // Add photo output
                if self.session.canAddOutput(self.output) {
                    self.session.addOutput(self.output)
                    // Enable high-resolution photo capture
                    self.output.isHighResolutionCaptureEnabled = true
                } else {
                    continuation.resume(throwing: CameraError.captureSessionFailed)
                    return
                }

                continuation.resume()
            }
        }
    }

    /// Start the camera session
    func start() {
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    /// Stop the camera session (MUST call on view disappear to prevent battery drain)
    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    /// Capture a photo
    func capturePhoto() async throws -> UIImage {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(throwing: CameraError.captureSessionFailed)
                return
            }

            self.photoContinuation = continuation

            let settings = AVCapturePhotoSettings()
            settings.flashMode = self.flashMode
            settings.photoQualityPrioritization = .balanced

            self.output.capturePhoto(with: settings, delegate: self)
        }
    }

    /// Toggle flash mode: auto → on → off → auto
    func toggleFlash() {
        switch flashMode {
        case .auto:
            flashMode = .on
        case .on:
            flashMode = .off
        case .off:
            flashMode = .auto
        @unknown default:
            flashMode = .auto
        }
    }

    /// Set zoom factor (clamped between 1.0 and device max, capped at 10.0)
    func setZoom(_ factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.device else { return }

            let maxZoomFactor = min(device.activeFormat.videoMaxZoomFactor, 10.0)
            let clampedFactor = min(max(factor, 1.0), maxZoomFactor)

            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = clampedFactor
                device.unlockForConfiguration()

                DispatchQueue.main.async {
                    self.currentZoomFactor = clampedFactor
                }
            } catch {
                print("Failed to set zoom factor: \(error)")
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoContinuation?.resume(throwing: error)
            photoContinuation = nil
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoContinuation?.resume(throwing: CameraError.imageProcessingFailed)
            photoContinuation = nil
            return
        }

        photoContinuation?.resume(returning: image)
        photoContinuation = nil
    }
}
