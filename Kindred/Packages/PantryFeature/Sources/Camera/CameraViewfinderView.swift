import AVFoundation
import SwiftUI
import UIKit

/// UIViewRepresentable that bridges AVCaptureVideoPreviewLayer to SwiftUI
struct CameraViewfinderView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // No updates needed
    }
}

/// UIView subclass with AVCaptureVideoPreviewLayer as layer class
final class CameraPreviewView: UIView {
    var session: AVCaptureSession? {
        get {
            previewLayer.session
        }
        set {
            previewLayer.session = newValue
        }
    }

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
