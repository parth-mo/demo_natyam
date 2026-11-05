import SwiftUI

struct ContentView: View {

    @StateObject private var cameraManager =
        CameraManager()
    @State private var showExploreMudras = false

    var body: some View {

        ZStack {

            // MARK: Camera

            CameraPreview(
                session:
                    cameraManager.session
            )
            .ignoresSafeArea()

            // MARK: Hand Landmarks

            HandLandmarkOverlay(
                points:
                    cameraManager.handPoints
            )
            .ignoresSafeArea()

            // MARK: UI

            VStack {

                HStack {
                    Text("Bharatanatyam Vision")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        showExploreMudras = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 12))
                            Text("Explore Mudras")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.70))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.25, green: 0.015, blue: 0.025).opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(red: 0.83, green: 0.63, blue: 0.37).opacity(0.5), lineWidth: 1))
                    }
                }
                .padding()
                .background(
                    .black.opacity(0.6)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                HStack {

                    Text(
                        "Hands: \(numberOfHands)"
                    )

                    Spacer()

                    Text(
                        "Points: \(cameraManager.handPoints.count)"
                    )
                }
                .foregroundStyle(.white)
                .padding()
                .background(
                    .black.opacity(0.6)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )
                .padding()
            }
        }
        .onAppear {

            cameraManager.startCamera()
        }
        .onDisappear {

            cameraManager.stopCamera()
        }
        .fullScreenCover(isPresented: $showExploreMudras) {
            NavigationStack {
                ExploreMudrasView()
            }
        }
    }

    private var numberOfHands: Int {

        let wristPoints =
            cameraManager.handPoints.filter {

                $0.name.contains(
                    "wrist"
                )
            }

        return wristPoints.count
    }
}
struct HandLandmarkOverlay:
    View {

    let points: [HandPoint]

    var body: some View {

        GeometryReader { geometry in

            ForEach(points) { point in

                Circle()
                    .fill(.red)
                    .frame(
                        width: 10,
                        height: 10
                    )
                    .position(

                        x:
                            point.x *
                            geometry.size.width,

                        y:
                            (1 - point.y) *
                            geometry.size.height
                    )
            }
        }
    }
}
