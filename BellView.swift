import SwiftUI
import SceneKit
import UIKit
import Combine   // ObservableObject / @Published

// ============================================================================
// SceneKit mudra globe, v2: detailed procedural ghungroos + braided rope.
//
// Self-contained: includes Mudra, MudraData and MudraDetailView.
// Do NOT add MudraGlobeView.swift (the SwiftUI version) to the same target.
//
// Ghungroo: PBR brass sphere, raised equator band, seam grooves, dark slit + round
//           sounding hole, gold eyelet loop and neck. The rope threads through the loop.
// Rope:     3 twisted red strands around a dark core (a real braided look), as vertex-coloured
//           geometry. Bells are strung on 4 latitude ropes; 3 longitude ropes close the cage.
// Optional: your own bell/rope assets (set GlobeConfig.preferProceduralModels = false).
// Mudra icons (optional): "mudra_0" ... "mudra_27" in Assets.xcassets.
// ============================================================================

private func cg(_ f: Float) -> CGFloat { CGFloat(f) }

// MARK: - Model

struct Mudra: Identifiable, Hashable {
    let id: Int
    let name: String
    let meaning: String
}

enum MudraData {
    private static let meanings: [String: String] = [
        // Asamyukta Hastas (Single Hand)
        "Pataka": "Flag — Represents clouds, forest, river, forbidding, shield, and blessings.",
        "Tripataka": "Three parts of flag — Represents a crown, tree, thunderbolt, and arrow.",
        "Ardhapataka": "Half flag — Represents two leaves, knife, dagger, flag, and temple tower.",
        "Kartarimukha": "Arrow face — Represents separation, corner of an eye, lightning, and falling.",
        "Mayura": "Peacock — Represents peacock neck, twisting hair, creeper, and graceful flight.",
        "Ardhachandra": "Half moon — Represents spear, consecration, plate, waist, and crescent.",
        "Arala": "Bent — Represents drinking nectar, poison, violent wind, and strong resolve.",
        "Shukatunda": "Parrot's beak — Represents shooting arrow, spear, remembering, and mystery.",
        "Mushti": "Fist — Represents grasping objects, combat, steadfastness, and endurance.",
        "Shikhara": "Spire / Peak — Represents God of Love, pillar, tooth, questioning, and silence.",
        "Kapitha": "Wood apple — Represents Goddess Lakshmi, Goddess Saraswati, holding flowers.",
        "Katakamukha": "Opening in link — Represents plucking flowers, wearing pearl necklace, bow.",
        "Suchi": "Needle — Represents number one, the universe, wheel, world, and sun.",
        "Chandrakala": "Crescent moon — Represents moon, Shiva's crest jewel, Ganga, and beauty.",
        "Padmakosha": "Lotus bud — Represents fruits, lotus bud, ball of flowers, and feeding.",
        "Sarpashirsha": "Snake head — Represents serpent, sandalwood paste, sprinkling, and giving.",
        "Mrigashirsha": "Deer head — Represents women, cheek, wheel, calling beloved, and fear.",
        "Simhamukha": "Lion face — Represents lion face, hare, elephant, coral, and divine power.",
        "Kangula": "Little bell / fruit — Represents betel fruit, bells worn by children, water lily.",
        "Alapadma": "Blooming lotus — Represents fully open lotus, beauty, circular motion, mirror.",
        "Chatura": "Clever / square — Represents musk, gold, copper, slow movement, eye expression.",
        "Bhramara": "Bee — Represents bee, parrot, wing, cuckoo, gentle breeze, and crane.",
        "Hamsasya": "Swan beak — Represents blessing, pearl, tying marriage thread, soft speaking.",
        "Hamsapaksha": "Swan wing — Represents number six, bridge, fingernail mark, and sheltering.",
        "Sandamsha": "Pincers — Represents number five, belly, wound, and sacrificial offering.",
        "Mukula": "Flower blossom — Represents eating, flower-arrows of Kamadeva, and offering.",
        "Tamrachuda": "Rooster crest — Represents rooster, crane, crow, camel, and inscribed leaf.",
        "Trishula": "Trident — Represents Trinity (Brahma, Vishnu, Shiva), sacred trident, wood apple.",

        // Samyukta Hastas (Double Hand)
        "Anjali": "Salutation — Reverence to deities, preceptors, and revered elders.",
        "Kapota": "Dove — Respectful greeting, receiving things, nodding in acceptance.",
        "Karkata": "Crab — Group arrival, stretching limbs, bending of branch.",
        "Svastika": "Crossed — Fear, dispute, praise, and auspicious beginning.",
        "Dola": "Swing — Commencement of natya, playful relaxation, and swaying swing.",
        "Pushpaputa": "Flower vessel — Offering lights, flowers, water, and fruits.",
        "Utsanga": "Embrace — Modesty, shyness, embrace, and teaching disciples.",
        "Shivalinga": "Phallic emblem — Symbol of Lord Shiva, cosmic pillar of light.",
        "Katakavardhana": "Crossed link — Royal coronation, worship, and wedding rituals.",
        "Kartarisvastika": "Crossed scissors — Stems, hills, trees, summits of mountains.",
        "Shakata": "Cart — The demon carriage, wheel, and chariot of gods.",
        "Shankha": "Conch shell — Sacred conch blown in temple rituals and battle.",
        "Chakra": "Wheel / Discus — Lord Vishnu's sacred discus, spinning wheel.",
        "Samputa": "Concealed box — Hiding things, secret casket, and sacred chest.",
        "Pasha": "Noose — Conflict, bondage, chain, and noose of Yama.",
        "Kilaka": "Bond — Affection, close friendship, and intimate conversation.",
        "Matsya": "Fish — Matsya incarnation of Lord Vishnu, and ocean creatures.",
        "Kurma": "Tortoise — Kurma incarnation of Lord Vishnu, and shielding shell.",
        "Varaha": "Boar — Varaha incarnation of Lord Vishnu, and boar tusk.",
        "Garuda": "Eagle — Celestial vehicle of Lord Vishnu, sacred eagle in flight.",
        "Nagabandha": "Serpent coil — Entwined serpents, sacred coils, and chambers.",
        "Khatva": "Bed / Cot — Palanquin, royal cot, and ceremonial seat.",
        "Bherunda": "Pair of birds — Twin-headed mythical bird of immense power.",
        "Avahittha": "Dissimulation — Modesty, concealing one's heart, beauty, and grace."
    ]

    static func mudras(for category: HastaCategory) -> [Mudra] {
        category.mudras.enumerated().map { i, name in
            Mudra(id: i, name: name, meaning: meanings[name] ?? "\(name) is an essential gesture in Bharatanatyam.")
        }
    }

    static var all: [Mudra] {
        mudras(for: .asamyukta)
    }
}

/// Destination page for a mudra, styled to match the Explore Mudras theme.
struct MudraDetailView: View {
    let mudra: Mudra
    var category: HastaCategory = .asamyukta
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.70))
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.88, blue: 0.70),
                                    Color(red: 0.83, green: 0.63, blue: 0.37),
                                    Color(red: 0.83, green: 0.63, blue: 0.37).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 150, height: 150)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.42, green: 0.03, blue: 0.05),
                                    Color(red: 0.25, green: 0.015, blue: 0.025),
                                    Color(red: 0.12, green: 0.005, blue: 0.012)
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 75
                            )
                        )
                        .frame(width: 136, height: 136)

                    if UIImage(named: category.handAsset) != nil {
                        Image(category.handAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .shadow(color: Color(red: 0.83, green: 0.63, blue: 0.37).opacity(0.6), radius: 6)
                    } else {
                        Image(systemName: category == .asamyukta ? "hand.raised.fill" : "hands.sparkles.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.70))
                            .shadow(color: Color(red: 0.83, green: 0.63, blue: 0.37).opacity(0.6), radius: 6)
                    }
                }

                VStack(spacing: 8) {
                    Text(String(format: "%02d • %@", mudra.id + 1, category.subtitle))
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(Color(red: 0.83, green: 0.63, blue: 0.37))

                    Text(mudra.name)
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.70))

                    Text(mudra.meaning)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white.opacity(0.62))
                        .padding(.horizontal, 36)
                        .padding(.top, 4)
                }

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Config (tweak these first)

enum GlobeConfig {
    enum RopeMode { case fullCage, rings }

    /// true  = detailed procedural ghungroos + braided rope (this file's models)
    /// false = load your own bell/rope assets (bell.usdz etc.), see the asset settings below
    static let preferProceduralModels = true

    // Globe layout
    static let globeRadius: Float = 1.6
    /// Bells are strung on these latitude ropes (sine of latitude, -1...1). 4 rings x 7 bells = 28.
    static let ringLatitudes: [Float] = [0.72, 0.24, -0.24, -0.72]
    static let cameraDistance: Float = 7.2

    // Procedural look
    static let ropeRadius: Float = 0.04         // rope thickness
    static let bellBodyRadius: Float = 0.17     // ghungroo ball radius
    static let showMedallion = true             // enamel mudra icon on each ghungroo

    // Your own assets (only used when preferProceduralModels == false)
    static let bellAssetName = "bell"
    static let ropeAssetName = "rope"
    static let ropeMode: RopeMode = .rings      // .fullCage = rope asset is a whole globe frame
    static let bellSize: Float = 0.5            // largest dimension of your bell
    static let ropeScale: Float = 1.0           // fullCage only
    static let bellModelCorrection = SIMD3<Float>(0, 0, 0)   // euler fix if the bell front isn't +Z
}

// MARK: - Asset loading helpers (for your own models)

enum AssetLoader {
    static func load(_ name: String) -> SCNNode? {
        let exts = ["usdz", "scn", "dae", "usdc"]
        let folders = ["", "art.scnassets/"]
        for folder in folders {
            for ext in exts {
                if let scene = SCNScene(named: "\(folder)\(name).\(ext)") {
                    let container = SCNNode()
                    for child in scene.rootNode.childNodes { container.addChildNode(child.clone()) }
                    return container
                }
            }
        }
        return nil
    }

    static func bounds(of root: SCNNode) -> (min: SIMD3<Float>, max: SIMD3<Float>)? {
        var lo = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var hi = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        var found = false
        root.enumerateHierarchy { n, _ in
            guard n.geometry != nil else { return }
            let (a, b) = n.boundingBox
            for x in [a.x, b.x] { for y in [a.y, b.y] { for z in [a.z, b.z] {
                let p = root.convertPosition(SCNVector3(x, y, z), from: n)
                let v = SIMD3<Float>(Float(p.x), Float(p.y), Float(p.z))
                lo = simd_min(lo, v); hi = simd_max(hi, v); found = true
            } } }
        }
        return found ? (lo, hi) : nil
    }

    static func normalized(_ node: SCNNode, targetSize: Float) -> SCNNode {
        let wrapper = SCNNode()
        wrapper.addChildNode(node)
        guard let b = bounds(of: node) else { return wrapper }
        let size = b.max - b.min
        let maxDim = max(size.x, max(size.y, size.z))
        guard maxDim > 0 else { return wrapper }
        node.simdPosition = -(b.min + b.max) / 2
        wrapper.simdScale = SIMD3<Float>(repeating: targetSize / maxDim)
        return wrapper
    }
}

// MARK: - Procedural mesh builder (tubes with per-vertex colour)

struct MeshBuilder {
    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var colors: [SIMD4<Float>] = []
    var indices: [Int32] = []

    /// Sweeps a circle of `radius` along `path`. `radialHint` gives a reference "outward" direction per
    /// point so the cross-section frame is stable and the loop closes without a seam.
    mutating func addTube(path: [SIMD3<Float>], radialHint: [SIMD3<Float>], radius: Float,
                          sides: Int, closed: Bool, colorAt: (Int) -> SIMD4<Float>) {
        let n = path.count
        guard n > 1 else { return }
        let base = Int32(positions.count)
        for i in 0..<n {
            let prev = path[closed ? (i + n - 1) % n : max(i - 1, 0)]
            let next = path[closed ? (i + 1) % n : min(i + 1, n - 1)]
            let t = simd_normalize(next - prev)
            let hint = radialHint[i]
            let nrm = simd_normalize(hint - simd_dot(hint, t) * t)
            let bin = simd_cross(t, nrm)
            let color = colorAt(i)
            for s in 0..<sides {
                let ang = 2 * Float.pi * Float(s) / Float(sides)
                let dir = cos(ang) * nrm + sin(ang) * bin
                positions.append(path[i] + radius * dir)
                normals.append(dir)
                colors.append(color)
            }
        }
        let segs = closed ? n : n - 1
        let sd = Int32(sides)
        for i in 0..<segs {
            let r0 = base + Int32(i) * sd
            let r1 = base + Int32((i + 1) % n) * sd
            for s in 0..<sides {
                let s1 = Int32((s + 1) % sides)
                let a = r0 + Int32(s), b = r0 + s1
                let c = r1 + Int32(s), d = r1 + s1
                indices.append(contentsOf: [a, b, c, b, d, c])
            }
        }
    }

    func geometry() -> SCNGeometry {
        let vs = SCNGeometrySource(vertices: positions.map { SCNVector3($0.x, $0.y, $0.z) })
        let ns = SCNGeometrySource(normals: normals.map { SCNVector3($0.x, $0.y, $0.z) })
        let cdata = colors.withUnsafeBufferPointer { Data(buffer: $0) }
        let cs = SCNGeometrySource(data: cdata, semantic: .color, vectorCount: colors.count,
                                   usesFloatComponents: true, componentsPerVector: 4,
                                   bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0,
                                   dataStride: MemoryLayout<SIMD4<Float>>.stride)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        return SCNGeometry(sources: [vs, ns, cs], elements: [element])
    }
}

// MARK: - Braided rope

enum BraidedRope {
    /// A closed braided ring lying in the XZ plane, centred on the origin.
    /// 3 twisted strands around a dark core; vertex colours fake the strands dipping in and out.
    /// Colored to match ExploreMudraView's arc section deep red velvet without glowing.
    static func ring(radius R: Float, tube r: Float) -> SCNNode {
        var mb = MeshBuilder()
        let strands = 3
        let pitchLen = r * 9                                   // rope length per full twist
        let twists = max(3, Int((2 * Float.pi * R / pitchLen).rounded()))
        let samples = max(180, twists * 16)
        let helixR = r * 0.50
        let strandR = r * 0.56

        var circle: [SIMD3<Float>] = []
        var radial: [SIMD3<Float>] = []
        for i in 0..<samples {
            let a = 2 * Float.pi * Float(i) / Float(samples)
            let n = SIMD3<Float>(cos(a), 0, sin(a))
            circle.append(n * R)
            radial.append(n)
        }

        // Deep maroon core fills the gaps between strands (matches arc section's deepest tone)
        mb.addTube(path: circle, radialHint: radial, radius: helixR, sides: 8, closed: true) { _ in
            SIMD4<Float>(0.14, 0.008, 0.014, 1.0)
        }

        // Strands colored to match the rich red velvet of ExploreMudraView's arc section:
        // Color(red: 0.38...0.42, green: 0.026...0.030, blue: 0.036...0.040)
        let shades: [Float] = [1.0, 0.88, 0.94]
        for k in 0..<strands {
            let phase = 2 * Float.pi * Float(k) / Float(strands)
            let shade = shades[k]
            var path: [SIMD3<Float>] = []
            for i in 0..<samples {
                let a = 2 * Float.pi * Float(i) / Float(samples)
                let n = SIMD3<Float>(cos(a), 0, sin(a))
                let psi = phase + Float(twists) * a
                let offset = (cos(psi) * n) + (sin(psi) * SIMD3<Float>(0, 1, 0))
                path.append(n * R + offset * helixR)
            }
            mb.addTube(path: path, radialHint: radial, radius: strandR, sides: 8, closed: true) { i in
                let psi = phase + Float(twists) * 2 * Float.pi * Float(i) / Float(samples)
                let l = 0.82 + 0.18 * (0.5 + 0.5 * cos(psi))
                let red: Float = 0.38 * shade * l
                let green: Float = 0.026 * shade * l
                let blue: Float = 0.036 * shade * l
                return SIMD4<Float>(red, green, blue, 1.0)
            }
        }

        let geo = mb.geometry()
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = UIColor.white          // multiplied by the vertex colours
        m.roughness.contents = 0.95                 // matte cord (no specular bloom)
        m.metalness.contents = 0.0                  // non-metallic fabric
        m.specular.contents = UIColor(white: 0.02, alpha: 1.0)
        m.emission.contents = UIColor.black         // completely non-glowing
        geo.materials = [m]
        return SCNNode(geometry: geo)
    }
}

// MARK: - Ghungroo (brass jingle bell)

struct BellTemplate {
    let node: SCNNode        // origin = the point on the rope the bell hangs from
    let bodyCenterY: Float   // centre of the ball, relative to that origin
    let bodyRadius: Float
}

enum BrassGhungroo {
    static func goldMaterial(roughness: CGFloat,
                             tint: UIColor = UIColor(red: 0.88, green: 0.66, blue: 0.25, alpha: 1)) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = tint
        m.metalness.contents = 1.0
        m.roughness.contents = roughness
        return m
    }

    static func make(bodyRadius r: Float) -> BellTemplate {
        let root = SCNNode()
        let bodyY = -1.25 * r

        let gold = goldMaterial(roughness: 0.24)
        let darkGold = goldMaterial(roughness: 0.42, tint: UIColor(red: 0.55, green: 0.37, blue: 0.12, alpha: 1))
        let dark = SCNMaterial()
        dark.lightingModel = .physicallyBased
        dark.diffuse.contents = UIColor(red: 0.04, green: 0.02, blue: 0.015, alpha: 1)
        dark.roughness.contents = 0.9
        dark.metalness.contents = 0.0

        let body = SCNNode()
        body.simdPosition = SIMD3<Float>(0, bodyY, 0)
        root.addChildNode(body)

        // Ball
        let sphere = SCNSphere(radius: cg(r))
        sphere.segmentCount = 72
        sphere.materials = [gold]
        body.addChildNode(SCNNode(geometry: sphere))

        // Raised equator band + two fine seam grooves
        let band = SCNTorus(ringRadius: cg(r * 0.995), pipeRadius: cg(r * 0.04))
        band.ringSegmentCount = 72
        band.pipeSegmentCount = 12
        band.materials = [gold]
        body.addChildNode(SCNNode(geometry: band))
        for dy: Float in [-0.075, 0.075] {
            let ringRadius = r * sqrt(1 - dy * dy) * 1.001
            let groove = SCNTorus(ringRadius: cg(ringRadius), pipeRadius: cg(r * 0.012))
            groove.ringSegmentCount = 72
            groove.pipeSegmentCount = 8
            groove.materials = [dark]
            let g = SCNNode(geometry: groove)
            g.simdPosition = SIMD3<Float>(0, dy * r, 0)
            body.addChildNode(g)
        }

        // Slit + round sounding hole, front and back
        var slit = MeshBuilder()
        for sign: Float in [1, -1] {
            var path: [SIMD3<Float>] = []
            var hint: [SIMD3<Float>] = []
            let steps = 24
            for s in 0...steps {
                let th = (128 + 46 * Float(s) / Float(steps)) * Float.pi / 180
                let n = SIMD3<Float>(0, cos(th), sign * sin(th))
                path.append(n * (r * 0.99))
                hint.append(n)
            }
            slit.addTube(path: path, radialHint: hint, radius: r * 0.032, sides: 6, closed: false) { _ in
                SIMD4<Float>(1, 1, 1, 1)
            }

            let thH = Float(114) * Float.pi / 180
            let nH = SIMD3<Float>(0, cos(thH), sign * sin(thH))
            let toNormal = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: nH)

            let disc = SCNCylinder(radius: cg(r * 0.1), height: cg(r * 0.012))
            disc.materials = [dark]
            let discNode = SCNNode(geometry: disc)
            discNode.simdPosition = nH * (r * 1.002)
            discNode.simdOrientation = toNormal
            body.addChildNode(discNode)

            let lip = SCNTorus(ringRadius: cg(r * 0.1), pipeRadius: cg(r * 0.016))
            lip.materials = [darkGold]
            let lipNode = SCNNode(geometry: lip)
            lipNode.simdPosition = nH * (r * 1.003)
            lipNode.simdOrientation = toNormal
            body.addChildNode(lipNode)
        }
        let slitGeo = slit.geometry()
        slitGeo.materials = [dark]
        body.addChildNode(SCNNode(geometry: slitGeo))

        // Eyelet loop (ring lies in the YZ plane so the rope runs through it along X) + neck
        let loop = SCNTorus(ringRadius: cg(r * 0.34), pipeRadius: cg(r * 0.07))
        loop.ringSegmentCount = 48
        loop.pipeSegmentCount = 16
        loop.materials = [gold]
        let loopNode = SCNNode(geometry: loop)
        loopNode.simdEulerAngles = SIMD3<Float>(0, 0, Float.pi / 2)
        root.addChildNode(loopNode)

        let neck = SCNCylinder(radius: cg(r * 0.16), height: cg(r * 0.2))
        neck.materials = [gold]
        let neckNode = SCNNode(geometry: neck)
        neckNode.simdPosition = SIMD3<Float>(0, -r * 0.33, 0)
        root.addChildNode(neckNode)

        return BellTemplate(node: root, bodyCenterY: bodyY, bodyRadius: r)
    }
}

// MARK: - Image helpers

enum ImageFactory {
    /// Dark-red enamel disc with a gold rim and the mudra icon on it.
    static func medallion(icon: UIImage) -> UIImage {
        let s: CGFloat = 256
        return UIGraphicsImageRenderer(size: CGSize(width: s, height: s)).image { ctx in
            let c = ctx.cgContext
            let rect = CGRect(x: 8, y: 8, width: s - 16, height: s - 16)
            let colors = [UIColor(red: 0.55, green: 0.08, blue: 0.10, alpha: 1).cgColor,
                          UIColor(red: 0.18, green: 0.01, blue: 0.02, alpha: 1).cgColor] as CFArray
            if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                c.saveGState()
                c.addEllipse(in: rect)
                c.clip()
                c.drawRadialGradient(grad, startCenter: CGPoint(x: s / 2, y: s * 0.4), startRadius: 0,
                                     endCenter: CGPoint(x: s / 2, y: s / 2), endRadius: s / 2, options: [])
                c.restoreGState()
            }
            UIColor(red: 0.95, green: 0.78, blue: 0.4, alpha: 1).setStroke()
            c.setLineWidth(10)
            c.strokeEllipse(in: rect.insetBy(dx: 5, dy: 5))

            let box = rect.insetBy(dx: 48, dy: 48)
            if icon.size.width > 0, icon.size.height > 0 {
                let sc = min(box.width / icon.size.width, box.height / icon.size.height)
                let w = icon.size.width * sc, h = icon.size.height * sc
                icon.draw(in: CGRect(x: box.midX - w / 2, y: box.midY - h / 2, width: w, height: h))
            }
        }
    }

    /// Small studio-style environment so the brass actually reflects something.
    static func environment() -> UIImage {
        let size = CGSize(width: 1024, height: 512)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let c = ctx.cgContext
            let colors = [UIColor(red: 0.30, green: 0.19, blue: 0.09, alpha: 1).cgColor,
                          UIColor(red: 0.02, green: 0.02, blue: 0.03, alpha: 1).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                c.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            }
            UIColor(white: 1, alpha: 0.95).setFill()
            c.fill(CGRect(x: 120, y: 90, width: 170, height: 90))
            UIColor(red: 1, green: 0.8, blue: 0.5, alpha: 0.9).setFill()
            c.fill(CGRect(x: 640, y: 120, width: 230, height: 70))
            UIColor(red: 1, green: 0.35, blue: 0.2, alpha: 0.6).setFill()
            c.fill(CGRect(x: 420, y: 300, width: 130, height: 60))
        }
    }
}

// MARK: - Globe controller (scene + rotation + picking)

final class MudraGlobeController: NSObject, ObservableObject, SCNSceneRendererDelegate {
    @Published private(set) var frontIndex = 0
    var onSelect: ((Int) -> Void)?

    let category: HastaCategory
    let mudras: [Mudra]

    let scene = SCNScene()
    let cameraNode = SCNNode()
    private let globe = SCNNode()
    private var bells: [SCNNode] = []
    private var glows: [SCNNode] = []
    private let points: [SIMD3<Float>]

    // Rotation state (guarded by `lock`: gestures run on main, rendering on SceneKit's thread)
    private let lock = NSLock()
    private var yaw: Float = 0
    private var pitch: Float = 0
    private var yawVel: Float = 0
    private var pitchVel: Float = 0
    private var dragging = false
    private struct Anim { var start: SIMD2<Float>; var end: SIMD2<Float>; var t0: TimeInterval?; var dur: TimeInterval }
    private var anim: Anim?
    private var lastTime: TimeInterval = 0
    private var lastFront = -1

    private let maxPitch: Float = 1.2

    init(category: HastaCategory = .asamyukta) {
        self.category = category
        self.mudras = MudraData.mudras(for: category)
        self.points = MudraGlobeController.layout(count: self.mudras.count)
        super.init()
        buildScene()
    }

    // MARK: Layout: bells strung on the latitude ropes

    private static func layout(count: Int) -> [SIMD3<Float>] {
        let lats = GlobeConfig.ringLatitudes
        let perRing = Int((Double(count) / Double(lats.count)).rounded(.up))
        var out: [SIMD3<Float>] = []
        for i in 0..<count {
            let j = i / perRing, k = i % perRing
            let y = lats[min(j, lats.count - 1)]
            let r = sqrt(1 - y * y)
            let stagger: Float = (j % 2 == 1) ? Float.pi / Float(perRing) : 0
            let a = Float.pi / 2 + 2 * Float.pi * Float(k) / Float(perRing) + stagger   // k = 0 faces the viewer
            out.append(SIMD3<Float>(r * cos(a), y, r * sin(a)))
        }
        return out
    }

    // MARK: Scene construction

    private func buildScene() {
        let dist = GlobeConfig.cameraDistance
        scene.background.contents = UIColor.black
        scene.fogColor = UIColor.black
        scene.fogStartDistance = CGFloat(dist - 1.2)      // back bells fade into the dark
        scene.fogEndDistance = CGFloat(dist + 3.2)
        scene.lightingEnvironment.contents = ImageFactory.environment()
        scene.lightingEnvironment.intensity = 1.3
        scene.rootNode.addChildNode(globe)

        let camera = SCNCamera()
        camera.fieldOfView = 38
        camera.wantsHDR = true
        camera.bloomIntensity = 0.6
        camera.bloomThreshold = 1.15
        camera.bloomBlurRadius = 6
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, dist)
        scene.rootNode.addChildNode(cameraNode)

        func light(_ type: SCNLight.LightType, _ intensity: CGFloat, _ color: UIColor, _ pos: SCNVector3) {
            let n = SCNNode()
            n.light = SCNLight()
            n.light?.type = type
            n.light?.intensity = intensity
            n.light?.color = color
            n.position = pos
            scene.rootNode.addChildNode(n)
        }
        light(.ambient, 250, UIColor(red: 1, green: 0.9, blue: 0.8, alpha: 1), SCNVector3Zero)
        light(.omni, 1300, UIColor(red: 1, green: 0.88, blue: 0.7, alpha: 1), SCNVector3(2, 3, 6))
        light(.omni, 700, UIColor(red: 1, green: 0.3, blue: 0.2, alpha: 1), SCNVector3(-4, -2, -3))

        addRopes()
        addFinials()
        addBells()
    }

    private func addRopes() {
        let R = GlobeConfig.globeRadius

        if GlobeConfig.preferProceduralModels {
            let tube = GlobeConfig.ropeRadius
            for y in GlobeConfig.ringLatitudes {
                let ring = BraidedRope.ring(radius: sqrt(1 - y * y) * R, tube: tube)
                ring.simdPosition = SIMD3<Float>(0, y * R, 0)
                globe.addChildNode(ring)
            }
            for k in 0..<3 {
                let holder = SCNNode()
                holder.eulerAngles.y = Float(k) * Float.pi / 3
                let ring = BraidedRope.ring(radius: R, tube: tube)
                ring.eulerAngles.x = Float.pi / 2
                holder.addChildNode(ring)
                globe.addChildNode(holder)
            }
            return
        }

        // Your own rope asset
        if GlobeConfig.ropeMode == .fullCage, let cage = AssetLoader.load(GlobeConfig.ropeAssetName) {
            globe.addChildNode(AssetLoader.normalized(cage, targetSize: R * 2 * GlobeConfig.ropeScale))
            return
        }
        func assetRing() -> SCNNode {
            if let asset = AssetLoader.load(GlobeConfig.ropeAssetName) {
                return AssetLoader.normalized(asset, targetSize: 2)
            }
            return BraidedRope.ring(radius: 1, tube: GlobeConfig.ropeRadius / R)
        }
        for y in GlobeConfig.ringLatitudes {
            let ring = assetRing()
            ring.simdScale = SIMD3<Float>(repeating: sqrt(1 - y * y) * R)
            ring.simdPosition = SIMD3<Float>(0, y * R, 0)
            globe.addChildNode(ring)
        }
        for k in 0..<3 {
            let holder = SCNNode()
            holder.eulerAngles.y = Float(k) * Float.pi / 3
            let ring = assetRing()
            ring.simdScale = SIMD3<Float>(repeating: R)
            ring.eulerAngles.x = Float.pi / 2
            holder.addChildNode(ring)
            globe.addChildNode(holder)
        }
    }

    /// Gold caps with a beaded finial where the longitude ropes meet at the poles.
    private func addFinials() {
        let gold = BrassGhungroo.goldMaterial(roughness: 0.25)
        func makeFinial() -> SCNNode {
            let root = SCNNode()
            func add(_ g: SCNGeometry, y: Float) {
                g.materials = [gold]
                let n = SCNNode(geometry: g)
                n.simdPosition = SIMD3<Float>(0, y, 0)
                root.addChildNode(n)
            }
            add(SCNCylinder(radius: 0.11, height: 0.12), y: 0.02)
            add(SCNSphere(radius: 0.08), y: 0.14)
            add(SCNCylinder(radius: 0.035, height: 0.06), y: 0.22)
            add(SCNSphere(radius: 0.06), y: 0.30)
            add(SCNCone(topRadius: 0, bottomRadius: 0.04, height: 0.14), y: 0.40)
            return root
        }
        let R = GlobeConfig.globeRadius
        let top = makeFinial()
        top.simdPosition = SIMD3<Float>(0, R, 0)
        globe.addChildNode(top)
        let bottom = makeFinial()
        bottom.simdPosition = SIMD3<Float>(0, -R, 0)
        bottom.eulerAngles.z = Float.pi
        globe.addChildNode(bottom)
    }

    private func makeBellTemplate() -> BellTemplate {
        if !GlobeConfig.preferProceduralModels, let asset = AssetLoader.load(GlobeConfig.bellAssetName) {
            let size = GlobeConfig.bellSize
            let norm = AssetLoader.normalized(asset, targetSize: size)
            norm.simdEulerAngles = GlobeConfig.bellModelCorrection
            norm.simdPosition = SIMD3<Float>(0, -size * 0.5, 0)
            let holder = SCNNode()
            holder.addChildNode(norm)
            return BellTemplate(node: holder, bodyCenterY: -size * 0.5, bodyRadius: size * 0.5)
        }
        return BrassGhungroo.make(bodyRadius: GlobeConfig.bellBodyRadius)
    }

    private func iconImage(for index: Int) -> UIImage {
        if let img = UIImage(named: "\(category.id.lowercased())_\(index)") ?? UIImage(named: "mudra_\(index)") {
            return img
        }
        let cfg = UIImage.SymbolConfiguration(pointSize: 120, weight: .regular)
        let sym = category == .asamyukta ? "hand.raised.fill" : "hands.sparkles.fill"
        return UIImage(systemName: sym, withConfiguration: cfg)?
            .withTintColor(UIColor(red: 0.95, green: 0.78, blue: 0.4, alpha: 1), renderingMode: .alwaysOriginal)
            ?? UIImage()
    }

    private func addBells() {
        let R = GlobeConfig.globeRadius
        let template = makeBellTemplate()
        let r = template.bodyRadius

        for (i, p) in points.enumerated() {
            // `bell` sits exactly on the rope; its orientation is set every frame so it hangs
            // straight down (gravity) and faces outward.
            let bell = SCNNode()
            bell.name = "bell_\(i)"
            bell.simdPosition = p * R
            globe.addChildNode(bell)

            // Pivot at the rope so the bell swings from its loop
            let sway = SCNNode()
            bell.addChildNode(sway)
            sway.addChildNode(template.node.clone())

            if GlobeConfig.showMedallion {
                let th = Float(58) * Float.pi / 180
                let n = SIMD3<Float>(0, cos(th), sin(th))
                let d = r * 0.8
                let plane = SCNPlane(width: cg(d), height: cg(d))
                plane.cornerRadius = cg(d / 2)
                plane.cornerSegmentCount = 24
                let img = ImageFactory.medallion(icon: iconImage(for: i))
                let mm = SCNMaterial()
                mm.lightingModel = .physicallyBased
                mm.diffuse.contents = img
                mm.emission.contents = img
                mm.emission.intensity = 0.4
                mm.metalness.contents = 0.2
                mm.roughness.contents = 0.35
                plane.materials = [mm]
                let node = SCNNode(geometry: plane)
                node.simdPosition = SIMD3<Float>(0, template.bodyCenterY, 0) + n * (r * 1.02)
                node.simdOrientation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: n)
                sway.addChildNode(node)
            }

            // Gentle sway about the rope, phase-shifted per bell
            let amp: CGFloat = 0.07
            let d = 1.1 + Double(i % 5) * 0.17
            let a1 = SCNAction.rotateBy(x: amp, y: 0, z: 0, duration: d)
            let a2 = SCNAction.rotateBy(x: -amp * 2, y: 0, z: 0, duration: d * 2)
            let a3 = SCNAction.rotateBy(x: amp, y: 0, z: 0, duration: d)
            [a1, a2, a3].forEach { $0.timingMode = .easeInEaseOut }
            sway.runAction(.repeatForever(.sequence([a1, a2, a3])))

            // Selection glow (additive halo, hidden until selected)
            let glowSphere = SCNSphere(radius: cg(r * 1.5))
            let gm = SCNMaterial()
            gm.diffuse.contents = UIColor.orange
            gm.transparency = 0.3
            gm.blendMode = .add
            gm.writesToDepthBuffer = false
            gm.lightingModel = .constant
            glowSphere.materials = [gm]
            let glow = SCNNode(geometry: glowSphere)
            glow.simdPosition = SIMD3<Float>(0, template.bodyCenterY, 0)
            glow.isHidden = true
            glow.renderingOrder = 10
            sway.addChildNode(glow)

            bells.append(bell)
            glows.append(glow)
        }
    }

    // MARK: Rotation helpers

    private func clampPitch(_ p: Float) -> Float { max(-maxPitch, min(maxPitch, p)) }

    private func shortest(_ a: Float) -> Float {
        var d = a.truncatingRemainder(dividingBy: 2 * Float.pi)
        if d > Float.pi { d -= 2 * Float.pi }
        if d < -Float.pi { d += 2 * Float.pi }
        return d
    }

    private func orientation(yaw: Float, pitch: Float) -> simd_quatf {
        simd_quatf(angle: pitch, axis: SIMD3<Float>(1, 0, 0)) * simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
    }

    /// Smoothly spins the globe so bell `index` faces the viewer.
    func rotate(to index: Int) {
        let p = points[index]
        let r = sqrt(p.x * p.x + p.z * p.z)
        let targetYaw = atan2(-p.x, p.z)
        let targetPitch = clampPitch(atan2(p.y, r))
        lock.lock(); defer { lock.unlock() }
        yawVel = 0; pitchVel = 0
        anim = Anim(start: SIMD2<Float>(yaw, pitch),
                    end: SIMD2<Float>(yaw + shortest(targetYaw - yaw), targetPitch),
                    t0: nil, dur: 0.7)
    }

    // MARK: Render loop

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let dt = Float(lastTime == 0 ? 0 : min(time - lastTime, 0.1))
        lastTime = time

        lock.lock()
        if var a = anim {
            if a.t0 == nil { a.t0 = time }
            let t = Float(min(1, max(0, (time - a.t0!) / a.dur)))
            let e = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2          // ease in-out
            yaw = a.start.x + (a.end.x - a.start.x) * e
            pitch = a.start.y + (a.end.y - a.start.y) * e
            anim = t >= 1 ? nil : a
        } else if !dragging {
            yaw += yawVel * dt
            pitch = clampPitch(pitch + pitchVel * dt)
            let decay = exp(-3 * dt)                                            // inertia
            yawVel *= decay; pitchVel *= decay
            if abs(yawVel) < 0.01 { yawVel = 0 }
            if abs(pitchVel) < 0.01 { pitchVel = 0 }
        }
        let q = orientation(yaw: yaw, pitch: pitch)
        lock.unlock()

        globe.simdOrientation = q

        // Keep every bell hanging straight down and facing outward, whatever the globe tilt is.
        let qInv = q.inverse
        var best = 0
        var bestZ = -Float.greatestFiniteMagnitude
        for i in points.indices {
            let n = q.act(points[i])
            let worldFacing = simd_quatf(angle: atan2(n.x, n.z), axis: SIMD3<Float>(0, 1, 0))
            bells[i].simdOrientation = qInv * worldFacing
            if n.z > bestZ { bestZ = n.z; best = i }
        }

        if best != lastFront {
            lastFront = best
            for i in bells.indices {
                let on = i == best
                glows[i].isHidden = !on
                bells[i].runAction(.scale(to: on ? 1.25 : 1.0, duration: 0.25))
            }
            DispatchQueue.main.async { self.frontIndex = best }
        }
    }

    // MARK: Gestures

    @objc func handlePan(_ g: UIPanGestureRecognizer) {
        guard let view = g.view else { return }
        let t = g.translation(in: view)
        g.setTranslation(.zero, in: view)
        let v = g.velocity(in: view)

        lock.lock(); defer { lock.unlock() }
        switch g.state {
        case .began:
            dragging = true; anim = nil; yawVel = 0; pitchVel = 0
        case .changed:
            yaw += Float(t.x) * 0.008
            pitch = clampPitch(pitch + Float(t.y) * 0.008)
        case .ended, .cancelled:
            dragging = false
            yawVel = Float(v.x) * 0.008
            pitchVel = Float(v.y) * 0.008
        default: break
        }
    }

    @objc func handleTap(_ g: UITapGestureRecognizer) {
        guard let view = g.view as? SCNView else { return }
        let hits = view.hitTest(g.location(in: view), options: [
            .searchMode: SCNHitTestSearchMode.all.rawValue,
            .ignoreHiddenNodes: true
        ])
        for hit in hits {
            var node: SCNNode? = hit.node
            while let n = node {
                if let name = n.name, name.hasPrefix("bell_"), let idx = Int(name.dropFirst(5)) {
                    // only front-half bells are tappable
                    if globe.simdOrientation.act(points[idx]).z > 0 {
                        DispatchQueue.main.async { self.onSelect?(idx) }
                    }
                    return
                }
                node = n.parent
            }
        }
    }
}

// MARK: - SwiftUI bridge

struct MudraSceneView: UIViewRepresentable {
    let controller: MudraGlobeController

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        v.scene = controller.scene
        v.pointOfView = controller.cameraNode
        v.delegate = controller
        v.backgroundColor = .black
        v.antialiasingMode = .multisampling4X
        v.rendersContinuously = true          // needed for inertia / sway / smooth spins
        v.allowsCameraControl = false
        v.addGestureRecognizer(UIPanGestureRecognizer(target: controller,
                                                      action: #selector(MudraGlobeController.handlePan(_:))))
        v.addGestureRecognizer(UITapGestureRecognizer(target: controller,
                                                      action: #selector(MudraGlobeController.handleTap(_:))))
        return v
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}

// MARK: - Screen

struct MudraSceneScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var globe: MudraGlobeController
    @State private var path: [Mudra] = []
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    let category: HastaCategory

    private var cream: Color { Color(red: 0.95, green: 0.85, blue: 0.7) }

    init(category: HastaCategory = .asamyukta) {
        self.category = category
        _globe = StateObject(wrappedValue: MudraGlobeController(category: category))
    }

    private var filteredMudras: [Mudra] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return [] }
        return globe.mudras.filter { mudra in
            mudra.name.lowercased().contains(query) ||
            mudra.meaning.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 10) {
                    header
                    searchBar
                    MudraSceneView(controller: globe)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    detailCard
                }
                .padding(.horizontal, 16)
            }
            .navigationDestination(for: Mudra.self) { MudraDetailView(mudra: $0, category: category) }
            .onAppear { globe.onSelect = { path.append(globe.mudras[$0]) } }   // tap a bell -> its page
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(cream)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("MUDRAS").font(.caption).tracking(3).foregroundStyle(.orange.opacity(0.8))
                Text(category.rawValue).font(.system(size: 34, design: .serif)).foregroundStyle(cream)
                Text("\(globe.mudras.count) \(category == .asamyukta ? "single" : "double") hand mudras • 3D Globe")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
        .padding(.top, 16)
    }

    private var searchBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.gray)

                TextField("Search mudras...", text: $searchText)
                    .font(.system(size: 15))
                    .foregroundStyle(cream)
                    .tint(cream)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit {
                        isSearchFocused = false
                        if let first = filteredMudras.first {
                            globe.rotate(to: first.id)
                        }
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        isSearchFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )

            if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                if filteredMudras.isEmpty {
                    Text("No mudra found for \"\(searchText)\"")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filteredMudras) { m in
                                Button {
                                    globe.rotate(to: m.id)
                                    isSearchFocused = false
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(m.name)
                                            .font(.system(size: 13, weight: .semibold, design: .serif))
                                        Text("#\(m.id + 1)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(globe.frontIndex == m.id ? .orange : .gray)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule().fill(
                                            globe.frontIndex == m.id ? Color.red.opacity(0.35) : Color.white.opacity(0.08)
                                        )
                                    )
                                    .overlay(
                                        Capsule().stroke(
                                            globe.frontIndex == m.id ? Color.orange.opacity(0.7) : Color.white.opacity(0.12),
                                            lineWidth: 1
                                        )
                                    )
                                    .foregroundStyle(cream)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 2)
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private var detailCard: some View {
        let mudras = globe.mudras
        let m = mudras.indices.contains(globe.frontIndex) ? mudras[globe.frontIndex] : mudras[0]
        return HStack(spacing: 12) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(m.name).font(.system(size: 26, design: .serif)).foregroundStyle(cream)
                    Text("\(m.id + 1) / \(mudras.count)").font(.footnote).foregroundStyle(.gray)
                    Text(m.meaning).font(.footnote).foregroundStyle(.gray).lineLimit(3)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture { path.append(m) }          // tap the text area to open the page

            HStack(spacing: 10) {
                Button {
                    let prev = (globe.frontIndex - 1 + mudras.count) % mudras.count
                    globe.rotate(to: prev)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.orange)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.red.opacity(0.25)))
                        .overlay(Circle().stroke(Color.red.opacity(0.6)))
                }

                Button {
                    let next = (globe.frontIndex + 1) % mudras.count
                    globe.rotate(to: next)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.orange)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.red.opacity(0.25)))
                        .overlay(Circle().stroke(Color.red.opacity(0.6)))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 28).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.08)))
        .padding(.bottom, 24)
    }
}

typealias BellView = MudraSceneScreen

#Preview { MudraSceneScreen() }
