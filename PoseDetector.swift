import Vision
import AVFoundation
import CoreVideo

struct HandPoint: Identifiable {

    let id = UUID()

    let name: String
    let x: CGFloat
    let y: CGFloat
    let confidence: Float
}

final class HandPoseDetector {

    private let visionQueue = DispatchQueue(
        label: "com.natya.handpose.vision",
        qos: .userInitiated
    )

    private let request =
        VNDetectHumanHandPoseRequest()

    init() {

        request.maximumHandCount = 2
    }

    func process(
        pixelBuffer: CVPixelBuffer,
        completion: @escaping ([HandPoint]) -> Void
    ) {

        visionQueue.async { [weak self] in

            guard let self = self else {
                return
            }

            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .leftMirrored,
                options: [:]
            )

            do {

                try handler.perform([
                    self.request
                ])

                guard let observations =
                    self.request.results
                else {

                    DispatchQueue.main.async {
                        completion([])
                    }

                    return
                }

                var points: [HandPoint] = []

                for observation in observations {

                    let recognizedPoints =
                        try observation.recognizedPoints(
                            .all
                        )

                    for (jointName, point)
                    in recognizedPoints {

                        guard point.confidence > 0.3
                        else {
                            continue
                        }

                        points.append(
                            HandPoint(
                                name: String(
                                    describing:
                                        jointName
                                ),
                                x: point.location.x,
                                y: point.location.y,
                                confidence:
                                    point.confidence
                            )
                        )
                    }
                }

                DispatchQueue.main.async {

                    completion(points)
                }

            } catch {

                print(
                    "❌ Vision error:",
                    error.localizedDescription
                )

                DispatchQueue.main.async {

                    completion([])
                }
            }
        }
    }
}
