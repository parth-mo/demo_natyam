import SwiftUI
import UIKit

// MARK: - Theme

enum HastaTheme {
    static let background = Color.black
    static let maroon = Color(red: 0.25, green: 0.015, blue: 0.025)
    static let deepMaroon = Color(red: 0.12, green: 0.005, blue: 0.012)
    static let brightMaroon = Color(red: 0.38, green: 0.025, blue: 0.035)
    static let gold = Color(red: 0.83, green: 0.63, blue: 0.37)
    static let lightGold = Color(red: 1.0, green: 0.88, blue: 0.70)
    static let muted = Color.white.opacity(0.62)

    static let margin: CGFloat = 22

    // Proportions measured from the design
    static let arcWidthRatio: CGFloat = 0.75       // oval width  / screen width
    static let arcHeightRatio: CGFloat = 0.74      // oval height / oval width
    static let backdropExtension: CGFloat = 0.015   // collar rises this much above the oval (fraction of oval height)

    static let goldStroke = LinearGradient(
        colors: [
            lightGold,
            gold,
            Color(red: 0.62, green: 0.44, blue: 0.22),
            lightGold
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func maroonRadial(startRadius: CGFloat = 5, endRadius: CGFloat) -> RadialGradient {
        RadialGradient(
            colors: [
                Color(red: 0.44, green: 0.02, blue: 0.035),
                Color(red: 0.26, green: 0.015, blue: 0.025),
                Color(red: 0.10, green: 0.005, blue: 0.012)
            ],
            center: .center,
            startRadius: startRadius,
            endRadius: endRadius
        )
    }
}
   
extension View {
    /// Tracked-out caps label used for eyebrows / metadata.
    func eyebrow(_ color: Color = HastaTheme.gold, tracking: CGFloat = 4) -> some View {
        self
            .font(.caption2.weight(.semibold))
            .tracking(tracking)
            .foregroundStyle(color)
    }
}

// MARK: - Category

enum HastaCategory: String, Identifiable, CaseIterable {
    case asamyukta = "Asamyukta"
    case samyukta = "Samyukta"

    var id: String { rawValue }

    var subtitle: String {
        self == .asamyukta
        ? "SINGLE HAND MUDRAS"
        : "DOUBLE HAND MUDRAS"
    }

    var handAsset: String {
        self == .asamyukta
        ? "AsamyuktaHand"
        : "SamyuktaHand"
    }

    var symbol: String {
        self == .asamyukta ? "hand.raised.fill" : "hands.sparkles.fill"
    }

    var mudras: [String] {
        switch self {
        case .asamyukta:
            return [
                "Pataka", "Tripataka", "Ardhapataka",
                "Kartarimukha", "Mayura", "Ardhachandra",
                "Arala", "Shukatunda", "Mushti",
                "Shikhara", "Kapittha", "Katakamukha",
                "Suchi", "Chandrakala", "Padmakosha",
                "Sarpashirsha", "Mrigashirsha", "Simhamukha",
                "Kangula", "Alapadma", "Chatura",
                "Bhramara", "Hamsasya", "Hamsapaksha",
                "Sandamsha", "Mukula", "Tamrachuda",
                "Trishula"
            ]

        case .samyukta:
            return [
                "Anjali", "Kapota", "Karkata",
                "Svastika", "Dola", "Pushpaputa",
                "Utsanga", "Shivalinga", "Katakavardhana",
                "Kartarisvastika", "Shakata", "Shankha",
                "Chakra", "Samputa", "Pasha",
                "Kilaka", "Matsya", "Kurma",
                "Varaha", "Garuda", "Nagabandha",
                "Khatva", "Bherunda", "Avahittha"
            ]
        }
    }
}

// MARK: - Panel Direction & Shapes

enum PanelDirection {
    case top
    case bottom
}

/// Half-ellipse "bowl" behind each oval.
/// `.top`    -> flat edge on top, bowl bowing downward (behind the upper oval)
/// `.bottom` -> flat edge on bottom, dome bowing upward (behind the lower oval)
struct HastaArchShape: Shape {

    enum Direction {
        case top
        case bottom
    }

    let direction: Direction

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let k: CGFloat = 0.5523          // quarter-ellipse bezier constant
        let rx = rect.width / 2
        let cx = rect.midX
        let h = rect.height

        switch direction {
        case .top:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addCurve(
                to: CGPoint(x: cx, y: rect.maxY),
                control1: CGPoint(x: rect.maxX, y: rect.minY + h * k),
                control2: CGPoint(x: cx + rx * k, y: rect.maxY)
            )
            path.addCurve(
                to: CGPoint(x: rect.minX, y: rect.minY),
                control1: CGPoint(x: cx - rx * k, y: rect.maxY),
                control2: CGPoint(x: rect.minX, y: rect.minY + h * k)
            )

        case .bottom:
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addCurve(
                to: CGPoint(x: cx, y: rect.minY),
                control1: CGPoint(x: rect.maxX, y: rect.maxY - h * k),
                control2: CGPoint(x: cx + rx * k, y: rect.minY)
            )
            path.addCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY),
                control1: CGPoint(x: cx - rx * k, y: rect.minY),
                control2: CGPoint(x: rect.minX, y: rect.maxY - h * k)
            )
        }

        path.closeSubpath()
        return path
    }
}

/// Geometry of the medallion: a lens (vesica) made of two circular arcs that meet in pointed tips.
/// The upper arc's centre sits below the lens, the lower arc's centre above it.
enum HastaLensGeometry {

    /// Radius of each arc for a lens of the given size.
    static func radius(for size: CGSize) -> CGFloat {
        let a = size.width / 2
        let b = size.height / 2
        return (a * a + b * b) / (2 * b)
    }

    /// Angle (radians, from the arc's mid-point) at which an arc reaches the lens tip.
    static func tipAngle(for size: CGSize) -> Double {
        let a = Double(size.width / 2)
        return asin(min(a / Double(radius(for: size)), 1))
    }

    /// Point on the upper (or lower) arc at `psiDeg` degrees from its mid-point (negative = left),
    /// with the outward normal / tangent angle in degrees. `mirrored` flips it vertically
    /// (used for the lower panel).
    static func sample(
        psiDeg: Double,
        onUpperArc: Bool,
        mirrored: Bool,
        size: CGSize
    ) -> (point: CGPoint, normalAngle: Double, tangentAngle: Double) {

        let R = Double(radius(for: size))
        let cx = Double(size.width / 2)
        let cy = Double(size.height / 2)
        let b = Double(size.height / 2)
        let psi = psiDeg * .pi / 180

        let x = cx + R * sin(psi)
        let nx = sin(psi)
        var y: Double
        var ny: Double

        if onUpperArc {
            let centreY = cy - b + R
            y = centreY - R * cos(psi)
            ny = -cos(psi)
        } else {
            let centreY = cy + b - R
            y = centreY + R * cos(psi)
            ny = cos(psi)
        }

        if mirrored {
            y = Double(size.height) - y
            ny = -ny
        }

        let normalDeg = atan2(ny, nx) * 180 / .pi
        return (CGPoint(x: x, y: y), normalDeg, normalDeg + 90)
    }
}

/// The lens-shaped medallion.
struct HastaLensShape: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = rect.size
        let psi0 = HastaLensGeometry.tipAngle(for: size) * 180 / .pi
        let steps = 90

        func point(_ psi: Double, upper: Bool) -> CGPoint {
            let s = HastaLensGeometry.sample(psiDeg: psi, onUpperArc: upper, mirrored: false, size: size)
            return CGPoint(x: rect.minX + s.point.x, y: rect.minY + s.point.y)
        }

        // upper arc, left tip -> right tip
        for i in 0...steps {
            let psi = -psi0 + 2 * psi0 * Double(i) / Double(steps)
            let p = point(psi, upper: true)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        // lower arc, right tip -> left tip
        for i in 0...steps {
            let psi = psi0 - 2 * psi0 * Double(i) / Double(steps)
            path.addLine(to: point(psi, upper: false))
        }
        path.closeSubpath()
        return path
    }
}

/// The red "semicircle" behind each medallion, plus its gold edge.
/// Its curve is the circle the lens's OUTER arc belongs to: below the lens tips it IS the lens's
/// outer arc; above them it keeps curving out to a vertical tangent and then rises straight to the
/// flat edge. `rect` is exactly 2R wide (R = that circle's radius) and spans from the flat edge to
/// the lens's outermost point.
struct HastaLensCollarShape: Shape {
    let direction: HastaArchShape.Direction
    /// Angle (degrees from the arc's mid-point) at which the lens tips sit on that circle.
    let tipAngleDeg: Double
    /// true -> only the two gold edge lines from the lens tips up to the flat edge,
    /// false -> the closed fill shape
    var edgesOnly: Bool = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let R = rect.width / 2
        let cx = rect.midX
        let isTop = direction == .top
        let centreY = isTop ? rect.maxY - R : rect.minY + R
        let flatY = isTop ? rect.minY : rect.maxY
        let steps = 60

        func arcPoint(_ psiDeg: Double) -> CGPoint {
            let psi = psiDeg * .pi / 180
            let x = cx + R * CGFloat(sin(psi))
            let dy = R * CGFloat(cos(psi))
            return CGPoint(x: x, y: isTop ? centreY + dy : centreY - dy)
        }

        if edgesOnly {
            for side in [-1.0, 1.0] {
                for i in 0...steps {
                    let psi = side * (tipAngleDeg + (90 - tipAngleDeg) * Double(i) / Double(steps))
                    let pt = arcPoint(psi)
                    if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                }
                path.addLine(to: CGPoint(x: cx + CGFloat(side) * R, y: flatY))
            }
        } else {
            path.move(to: CGPoint(x: rect.minX, y: flatY))
            for i in 0...steps {
                let psi = -90 + 180 * Double(i) / Double(steps)
                path.addLine(to: arcPoint(psi))
            }
            path.addLine(to: CGPoint(x: rect.maxX, y: flatY))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Reusable Pieces

/// 44×44 circular icon button with an accessibility label.
struct HastaIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(HastaTheme.lightGold)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.06), in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle(scale: 0.92))
        .accessibilityLabel(label)
    }
}

/// Gold hairlines flanking a small lotus.
struct OrnamentDivider: View {
    var lineWidth: CGFloat = 34
    var ornamentSize: CGFloat = 20

    var body: some View {
        HStack(spacing: 8) {
            line(reversed: false)
            LotusShape()
                .stroke(HastaTheme.gold, lineWidth: 1.1)
                .frame(width: ornamentSize, height: ornamentSize * 0.8)
            line(reversed: true)
        }
        .accessibilityHidden(true)
    }

    private func line(reversed: Bool) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: reversed
                        ? [HastaTheme.gold, HastaTheme.gold.opacity(0.1)]
                        : [HastaTheme.gold.opacity(0.1), HastaTheme.gold],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: lineWidth, height: 1)
    }
}

// MARK: - Finials & Lotus Ornaments

/// Filigree arms that sweep out from the lotus base and curl back up (or down when inverted).
struct LotusFlourishShape: Shape {
    var inverted: Bool = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let w = rect.width
        let h = rect.height
        let s: CGFloat = inverted ? -1 : 1
        let baseY = inverted ? rect.minY : rect.maxY

        func y(_ k: CGFloat) -> CGFloat { baseY - s * h * k }

        for side: CGFloat in [-1, 1] {
            path.move(to: CGPoint(x: cx, y: y(0.10)))
            path.addCurve(
                to: CGPoint(x: cx + side * w * 0.46, y: y(0.36)),
                control1: CGPoint(x: cx + side * w * 0.16, y: y(-0.02)),
                control2: CGPoint(x: cx + side * w * 0.40, y: y(0.10))
            )
            // tight curl at the tip
            path.addQuadCurve(
                to: CGPoint(x: cx + side * w * 0.38, y: y(0.66)),
                control: CGPoint(x: cx + side * w * 0.54, y: y(0.62))
            )
        }
        return path
    }
}

/// Three-petal lotus shape.
struct LotusShape: Shape {
    var inverted: Bool = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let w = rect.width
        let h = rect.height
        let dir: CGFloat = inverted ? -1 : 1
        let base = inverted ? rect.minY : rect.maxY
        let tip = inverted ? rect.maxY : rect.minY

        // Centre petal
        path.move(to: CGPoint(x: cx, y: base))
        path.addQuadCurve(
            to: CGPoint(x: cx, y: tip),
            control: CGPoint(x: cx + w * 0.25, y: base - dir * h * 0.55)
        )
        path.addQuadCurve(
            to: CGPoint(x: cx, y: base),
            control: CGPoint(x: cx - w * 0.25, y: base - dir * h * 0.55)
        )

        // Side petals
        for side: CGFloat in [-1, 1] {
            path.move(to: CGPoint(x: cx, y: base))
            path.addQuadCurve(
                to: CGPoint(x: cx + side * w * 0.44, y: base - dir * h * 0.65),
                control: CGPoint(x: cx + side * w * 0.46, y: base - dir * h * 0.18)
            )
            path.addQuadCurve(
                to: CGPoint(x: cx, y: base),
                control: CGPoint(x: cx + side * w * 0.12, y: base - dir * h * 0.48)
            )
        }
        return path
    }
}

/// Finial at the far end of each oval: dot, stem, lotus with flourishes at its base.
struct EndOrnament: View {
    var inverted: Bool = false
    var width: CGFloat = 74
    var height: CGFloat = 46

    var body: some View {
        VStack(spacing: 2) {
            if !inverted {
                dot
                stem
                bloom
            } else {
                bloom
                stem
                dot
            }
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }

    private var dot: some View {
        Circle()
            .fill(HastaTheme.gold)
            .frame(width: 3.5, height: 3.5)
    }

    private var stem: some View {
        Rectangle()
            .fill(HastaTheme.gold.opacity(0.75))
            .frame(width: 1, height: 6)
    }

    private var bloom: some View {
        ZStack(alignment: inverted ? .top : .bottom) {
            LotusFlourishShape(inverted: inverted)
                .stroke(HastaTheme.gold.opacity(0.85), lineWidth: 1.1)
                .frame(width: width, height: 18)

            LotusShape(inverted: inverted)
                .stroke(HastaTheme.gold, lineWidth: 1.25)
                .frame(width: 24, height: 26)
        }
        .frame(width: width, height: 26)
    }
}

/// Subtle press feedback.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Main Screen

struct ExploreMudrasView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var topDrag: CGFloat = 0
    @State private var bottomDrag: CGFloat = 0
    @State private var didNudge = false
    @State private var releaseCount = 0

    @State private var selectedCategory: HastaCategory? = nil
    @State private var showBellView = false

    private let threshold: CGFloat = 65
    private let centreGap: CGFloat = 24
    private let endOrnamentHeight: CGFloat = 46

    var body: some View {
        ZStack {
            HastaTheme.background
                .ignoresSafeArea()

            gateScreen
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .medium), trigger: releaseCount)
        .fullScreenCover(isPresented: $showBellView) {
            BellView(category: selectedCategory ?? .asamyukta)
        }
    }

    // MARK: Gate screen

    private var gateScreen: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, HastaTheme.margin)
                .padding(.top, 8)

            Spacer(minLength: 8)

            GeometryReader { geo in
                let ornaments = endOrnamentHeight * 2 + centreGap
                let availableHeight = max(geo.size.height - ornaments, 200)
                // Oval height if it uses the design's width ratio
                let idealHeight = geo.size.width * HastaTheme.arcWidthRatio * HastaTheme.arcHeightRatio
                // On short screens shrink the whole oval proportionally instead of squashing it into a lens
                let widthScale = min(1, availableHeight / (2 * idealHeight))
                let sectionHeight = idealHeight * widthScale

                gates(sectionHeight: sectionHeight, widthScale: widthScale)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .padding(.bottom, 12)
        }
        .task { await nudge() }
    }

    private func gates(sectionHeight: CGFloat, widthScale: CGFloat) -> some View {
        VStack(spacing: 0) {

            EndOrnament(inverted: false)
                .frame(height: endOrnamentHeight)

            // UPPER: Asamyukta
            HastaPanel(
                category: .asamyukta,
                direction: .top,
                height: sectionHeight,
                widthScale: widthScale,
                threshold: threshold,
                dragOffset: $topDrag,
                onDragEnded: { pull in finishDrag(pull: pull, category: .asamyukta) },
                onTap: { openCategory(.asamyukta) }
            )
            .offset(y: topDrag)
            .zIndex(2)

            Spacer()
                .frame(height: centreGap)

            // LOWER: Samyukta
            HastaPanel(
                category: .samyukta,
                direction: .bottom,
                height: sectionHeight,
                widthScale: widthScale,
                threshold: threshold,
                dragOffset: $bottomDrag,
                onDragEnded: { pull in finishDrag(pull: pull, category: .samyukta) },
                onTap: { openCategory(.samyukta) }
            )
            .offset(y: bottomDrag)
            .zIndex(1)

            EndOrnament(inverted: true)
                .frame(height: endOrnamentHeight)
        }
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    // MARK: Header — back button and title both on the left

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {

            HastaIconButton(systemName: "chevron.left", label: "Back") {
                dismiss()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("EXPLORE")
                    .eyebrow(tracking: 4)

                Text("Mudras")
                    .font(.system(size: 38, weight: .regular, design: .serif))
                    .foregroundStyle(HastaTheme.lightGold)

                Text("The language of expression")
                    .font(.system(size: 13))
                    .foregroundStyle(HastaTheme.muted)

                OrnamentDivider(lineWidth: 34, ornamentSize: 20)
                    .padding(.top, 6)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)
        }
    }

    // MARK: Behaviour

    private func openCategory(_ category: HastaCategory) {
        selectedCategory = category
        showBellView = true
    }

    private func finishDrag(pull: CGFloat, category: HastaCategory) {
        if pull >= threshold {
            releaseCount += 1
            openCategory(category)
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
            topDrag = 0
            bottomDrag = 0
        }
    }

    private func bounce(amount: CGFloat = 16) async {
        guard !reduceMotion, topDrag == 0, bottomDrag == 0 else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
            topDrag = amount
            bottomDrag = -amount
        }
        try? await Task.sleep(for: .milliseconds(350))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            topDrag = 0
            bottomDrag = 0
        }
    }

    private func nudge() async {
        guard !didNudge else { return }
        didNudge = true
        try? await Task.sleep(for: .milliseconds(700))
        await bounce()
    }
}

// MARK: - Interactive Arch Panel

struct HastaPanel: View {

    let category: HastaCategory
    let direction: PanelDirection
    let height: CGFloat
    var widthScale: CGFloat = 1
    let threshold: CGFloat

    @Binding var dragOffset: CGFloat
    let onDragEnded: (CGFloat) -> Void
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title2) private var nameSize: CGFloat = 26
    @ScaledMetric(relativeTo: .caption2) private var subtitleSize: CGFloat = 9.5

    private let innerBellCount = 17
    private let bellSize: CGFloat = 30

    private var isTop: Bool { direction == .top }
    private var crossed: Bool { abs(dragOffset) >= threshold }
    private var progress: Double { min(Double(abs(dragOffset) / threshold), 1) }

    /// One bell on the rim. `outside == false` -> hangs inside the oval, `true` -> hangs outside it.
    private struct BellPlacement {
        let degrees: Double
        let outside: Bool
    }

    var body: some View {

        GeometryReader { geo in

            let width = geo.size.width
            let arcWidth = width * HastaTheme.arcWidthRatio * widthScale
            let arcHeight = arcWidth * HastaTheme.arcHeightRatio     // always keeps the design's round proportions
            let arcSize = CGSize(width: arcWidth, height: arcHeight)

            ZStack {
                // Extended outer arch (bowl above / dome below) that the oval sits inside
                sectionArchBackdrop(ovalWidth: arcWidth, ovalHeight: arcHeight)

                // Oval medallion with golden rim
                ovalArcMedallion(size: arcSize)

                // Ghungroo bells around the rim
                bells(size: arcSize)

                // Hand art, title, subtitle, chevron
                content(size: arcSize)
            }
            .frame(width: width, height: height)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onTapGesture(perform: onTap)
        }
        .frame(height: height)
        .sensoryFeedback(.impact(weight: .light), trigger: crossed) { _, new in new }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(category.rawValue), \(category.subtitle.lowercased())")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Section Backdrop

    private func sectionArchBackdrop(ovalWidth: CGFloat, ovalHeight: CGFloat) -> some View {
        // The red "semicircle" is the circle the lens's outer arc belongs to. It hugs the lens below
        // the tips, bulges out past them to a vertical tangent, then rises straight to the flat edge.
        // The gold edge line runs along exactly this curve, so it always stays on the red's border.
        let lensSize = CGSize(width: ovalWidth, height: ovalHeight)
        let R = HastaLensGeometry.radius(for: lensSize)
        let tipDeg = HastaLensGeometry.tipAngle(for: lensSize) * 180 / .pi
        let extra = ovalHeight * HastaTheme.backdropExtension
        let frameHeight = ovalHeight + extra
        let dir: HastaArchShape.Direction = isTop ? .top : .bottom

        let fadeStart: UnitPoint = isTop ? .top : .bottom
        let fadeEnd: UnitPoint = isTop ? .bottom : .top

        return ZStack {
            // Red velvet semicircle
            HastaLensCollarShape(direction: dir, tipAngleDeg: tipDeg)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.55, green: 0.045, blue: 0.055), location: 0.0),
                            .init(color: Color(red: 0.40, green: 0.028, blue: 0.040), location: 0.12),
                            .init(color: Color(red: 0.26, green: 0.015, blue: 0.026), location: 0.30),
                            .init(color: Color(red: 0.20, green: 0.010, blue: 0.020), location: 0.5),
                            .init(color: Color(red: 0.26, green: 0.015, blue: 0.026), location: 0.70),
                            .init(color: Color(red: 0.40, green: 0.028, blue: 0.040), location: 0.88),
                            .init(color: Color(red: 0.55, green: 0.045, blue: 0.055), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                // smooth fade into black at the flat edge
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black.opacity(0.35), location: 0.12),
                            .init(color: .black, location: 0.34)
                        ],
                        startPoint: fadeStart,
                        endPoint: fadeEnd
                    )
                )

            // Gold edge: same solid line as the lens rim, continuing along the red's border
            HastaLensCollarShape(direction: dir, tipAngleDeg: tipDeg, edgesOnly: true)
                .stroke(
                    HastaTheme.goldStroke,
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: HastaTheme.gold.opacity(0.35), radius: 8)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black.opacity(0.35), location: 0.12),
                            .init(color: .black, location: 0.30)
                        ],
                        startPoint: fadeStart,
                        endPoint: fadeEnd
                    )
                )
        }
        .frame(width: R * 2, height: frameHeight)
        .offset(y: isTop ? -extra / 2 : extra / 2)
        .allowsHitTesting(false)
    }

    // MARK: Oval Medallion & Golden Rim

    private func ovalArcMedallion(size: CGSize) -> some View {
        ZStack {
            HastaLensShape()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.47, green: 0.030, blue: 0.045),
                            Color(red: 0.34, green: 0.020, blue: 0.030),
                            Color(red: 0.22, green: 0.012, blue: 0.020)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: size.width * 0.62
                    )
                )
                // soft red halo so the lens edge melts into the collar
                .shadow(color: Color(red: 0.34, green: 0.02, blue: 0.03).opacity(0.5), radius: 16)

            HastaLensShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            HastaTheme.lightGold,
                            HastaTheme.gold,
                            Color(red: 0.65, green: 0.45, blue: 0.22),
                            HastaTheme.lightGold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2.4 + CGFloat(progress * 0.8), lineJoin: .round)
                )
                .shadow(
                    color: HastaTheme.gold.opacity(0.35 + 0.35 * progress),
                    radius: 8 + 6 * progress,
                    x: 0,
                    y: 0
                )

        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: Bells

    /// Inside bells along the rim facing away from the centre.
    private var bellPlacements: [BellPlacement] {
        // `degrees` = angle along the arc measured from its mid-point (negative = left).
        // Inside bells: 17 along the arc facing away from the centre, ~9.3 degrees apart.
        let inner = (-8...8).map { Double($0) * 9.3 }
        return inner.map { BellPlacement(degrees: $0, outside: false) }
    }

    private func bells(size: CGSize) -> some View {
        let placements = bellPlacements

        return ZStack {
            ForEach(Array(placements.enumerated()), id: \.offset) { i, placement in
                bell(index: i, placement: placement, size: size)
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }

    private func bell(index: Int, placement: BellPlacement, size: CGSize) -> some View {
        let sample = HastaLensGeometry.sample(
            psiDeg: placement.degrees,
            onUpperArc: !placement.outside,
            mirrored: !isTop,
            size: size
        )

        var sway = 0.0
        var jingle: CGFloat = 0
        if !reduceMotion {
            let wave = Double(index) * 0.65 + Double(dragOffset) * 0.08
            let pull = Double(abs(dragOffset))
            sway = sin(wave) * min(pull * 0.14, 12)
            jingle = CGFloat(cos(wave) * min(pull * 0.04, 3))
        }

        // The bell's loop touches the rim; its body points inward or outward along the normal.
        let normalRad = sample.normalAngle * .pi / 180.0
        let dist: CGFloat = bellSize * 0.42 * (placement.outside ? 1 : -1)
        let px = sample.point.x + CGFloat(cos(normalRad)) * dist
        let py = sample.point.y + CGFloat(sin(normalRad)) * dist

        let rotation = placement.outside
            ? sample.normalAngle - 90.0
            : sample.normalAngle + 90.0

        return Ghungroo(
            size: bellSize,
            angle: .degrees(rotation + sway),
            jingleOffset: jingle,
            glowOpacity: 0.2 + 0.3 * progress
        )
        .position(x: px, y: py)
    }

    // MARK: Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let pull = max(isTop ? value.translation.height : -value.translation.height, 0)
                let resisted = resist(pull)
                dragOffset = isTop ? resisted : -resisted
            }
            .onEnded { value in
                let pull = max(isTop ? value.translation.height : -value.translation.height, 0)
                onDragEnded(pull)
            }
    }

    private func resist(_ pull: CGFloat) -> CGFloat {
        guard pull > threshold else { return pull }
        return min(threshold + (pull - threshold) * 0.3, threshold + 45)
    }

    // MARK: Content

    private func content(size: CGSize) -> some View {
        VStack(spacing: 6) {

            handArt
                .frame(height: size.height * 0.38)

            Text(category.rawValue)
                .font(.system(size: nameSize, weight: .regular, design: .serif))
                .foregroundStyle(HastaTheme.lightGold)
                .shadow(color: HastaTheme.gold.opacity(0.3), radius: 3)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(category.subtitle)
                .font(.system(size: subtitleSize, weight: .medium))
                .tracking(2.8)
                .foregroundStyle(Color.white.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Button(action: onTap) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HastaTheme.gold)
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(HastaTheme.gold.opacity(0.75), lineWidth: 1))
            }
            .buttonStyle(PressableStyle(scale: 0.88))
            .padding(.top, 4)
            .accessibilityHidden(true)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: size.width * 0.72)
        // upper oval's content sits slightly below centre in the design
        .position(x: size.width / 2, y: size.height * (isTop ? 0.54 : 0.50))
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private var handArt: some View {
        if UIImage(named: category.handAsset) != nil {
            Image(category.handAsset)
                .resizable()
                .scaledToFit()
                .shadow(color: HastaTheme.gold.opacity(0.35), radius: 5)
        } else {
            CategoryHandEmblem(category: category, size: height * 0.34)
        }
    }
}

// MARK: - Category Emblem (Fallback)

struct CategoryHandEmblem: View {
    let category: HastaCategory
    var size: CGFloat = 70

    var body: some View {
        ZStack {
            Circle()
                .fill(HastaTheme.maroonRadial(endRadius: size * 0.5))
                .frame(width: size * 0.9, height: size * 0.9)

            Circle()
                .stroke(HastaTheme.goldStroke, lineWidth: 1.4)
                .frame(width: size, height: size)

            Image(systemName: category.symbol)
                .font(.system(size: size * 0.38))
                .foregroundStyle(HastaTheme.lightGold)
                .shadow(color: HastaTheme.gold.opacity(0.5), radius: 4)

            Ghungroo(size: size * 0.28, angle: .degrees(12), glowOpacity: 0.5)
                .offset(x: size * 0.34, y: size * 0.32)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Ghungroo

struct Ghungroo: View {

    var size: CGFloat = 22
    var angle: Angle = .zero
    var jingleOffset: CGFloat = 0
    var glowOpacity: Double = 0.4

    var body: some View {
        Image("GhungrooBell_Isolated")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .rotationEffect(angle)
            .offset(y: jingleOffset)
            .shadow(color: Color.black.opacity(0.4), radius: 2.5, x: 0, y: 1.5)
            .shadow(color: HastaTheme.gold.opacity(glowOpacity), radius: 4, x: 0, y: 0)
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExploreMudrasView()
    }
    .preferredColorScheme(.light)
}
