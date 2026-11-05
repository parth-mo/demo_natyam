import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(
        context: Context
    ) -> PreviewView {

        let view = PreviewView()

        view.videoPreviewLayer.session =
            session

        // Keep aspect ratio while initially
        // solving landmark alignment.
        view.videoPreviewLayer.videoGravity =
            .resizeAspect

        configurePreviewConnection(
            view.videoPreviewLayer
        )

        return view
    }

    func updateUIView(
        _ uiView: PreviewView,
        context: Context
    ) {

        uiView.videoPreviewLayer.session =
            session

        configurePreviewConnection(
            uiView.videoPreviewLayer
        )
    }

    private func configurePreviewConnection(
        _ layer: AVCaptureVideoPreviewLayer
    ) {

        guard let connection = layer.connection
        else {
            return
        }

        let rotationAngle: CGFloat = 90

        if connection.isVideoRotationAngleSupported(
            rotationAngle
        ) {

            connection.videoRotationAngle =
                rotationAngle
        }

        if connection.isVideoMirroringSupported {

            connection.isVideoMirrored = true
        }
    }
}

// MARK: - Preview View

final class PreviewView: UIView {

    override class var layerClass: AnyClass {

        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer:
        AVCaptureVideoPreviewLayer {

        layer as!
            AVCaptureVideoPreviewLayer
    }
}
