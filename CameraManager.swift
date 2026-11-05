import Foundation
import AVFoundation
import Combine

final class CameraManager: NSObject, ObservableObject {

    let session = AVCaptureSession()

    @Published var handPoints: [HandPoint] = []

    private let videoOutput = AVCaptureVideoDataOutput()

    private let videoQueue = DispatchQueue(
        label: "com.natya.camera.video",
        qos: .userInitiated
    )

    private let handDetector = HandPoseDetector()

    override init() {
        super.init()
        configureCamera()
    }

    // MARK: - Camera Setup

    private func configureCamera() {

        session.beginConfiguration()

        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else {

            print("❌ Front camera unavailable")

            session.commitConfiguration()
            return
        }

        do {

            let input = try AVCaptureDeviceInput(
                device: camera
            )

            if session.canAddInput(input) {
                session.addInput(input)
            }

        } catch {

            print(
                "❌ Camera input error:",
                error.localizedDescription
            )
        }

        // MARK: Video Output

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_32BGRA
        ]

        videoOutput.alwaysDiscardsLateVideoFrames = true

        videoOutput.setSampleBufferDelegate(
            self,
            queue: videoQueue
        )

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // MARK: Camera Rotation

        if let connection = videoOutput.connection(
            with: .video
        ) {

            let rotationAngle: CGFloat = 90

            if connection.isVideoRotationAngleSupported(
                rotationAngle
            ) {

                connection.videoRotationAngle =
                    rotationAngle
            }

            // Mirror front camera
            if connection.isVideoMirroringSupported {

                connection.isVideoMirrored = true
            }
        }

        session.commitConfiguration()
    }

    // MARK: - Start Camera

    func startCamera() {

        AVCaptureDevice.requestAccess(
            for: .video
        ) { [weak self] granted in

            guard granted else {

                print("❌ Camera permission denied")
                return
            }

            guard let self = self else {
                return
            }

            DispatchQueue.global(
                qos: .userInitiated
            ).async {

                if !self.session.isRunning {

                    self.session.startRunning()
                }
            }
        }
    }

    // MARK: - Stop Camera

    func stopCamera() {

        if session.isRunning {

            session.stopRunning()
        }
    }
}

// MARK: - Video Delegate

extension CameraManager:
    AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

        guard let pixelBuffer =
            CMSampleBufferGetImageBuffer(
                sampleBuffer
            )
        else {
            return
        }

        handDetector.process(
            pixelBuffer: pixelBuffer
        ) { [weak self] points in

            self?.handPoints = points
        }
    }
}
