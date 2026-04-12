//
//  GeneratedAssetFactory.swift
//  GlassVision
//
//  Created by Codex on 4/9/26.
//

import Foundation
import RealityKit
import UIKit
import simd

enum GeneratedAssetFactory {
    static let hiddenTargetGroup = CollisionGroup(rawValue: 1 << 2)
    static let hiddenOccluderGroup = CollisionGroup(rawValue: 1 << 3)
    static let portalInteractionGroup = CollisionGroup(rawValue: 1 << 4)
    private static let bundledObjectScale: Float = 1.0 / 3.2
    private static let bundledObjectScaleMultiplierByAssetID: [String: Float] = [
        "feather_quill": 2.1,
        "hourglass": 2.2,
        "crystal_ball": 2.0,
        "potion_bottle": 2.1,
        "spell_book": 2.0,
        "key": 5.0,
        "candle": 5.0,
        "wand": 5.0,
        "moon_charm": 2.3,
        "tiny_dragon_figurine": 2.3
    ]
    private static var loadedObjectTemplates: [String: Entity] = [:]
    private static var missingObjectNames: Set<String> = []

    // Temporary mapping until puzzle JSON is updated to point directly at object file names.
    private static let objectResourceNameByAssetID: [String: String] = [
        "feather_quill": "CrystalLotus",
        "hourglass": "GemCoin",
        "crystal_ball": "goldendice",
        "potion_bottle": "MagmaExplosion",
        "spell_book": "ufo",
        "key": "car-coupe-blue",
        "candle": "car-coupe-green",
        "wand": "car-coupe-citrus",
        "moon_charm": "GemCoin",
        "tiny_dragon_figurine": "ufo"
    ]

    struct LookingGlassAssembly {
        let root: Entity
        let handleHitTarget: Entity
        let portalDiskFront: ModelEntity
        let portalDiskBack: ModelEntity
        let debugRing: ModelEntity
        let homeTransform: Transform
    }

    static func makeLookingGlass(portalRadius: Float) -> LookingGlassAssembly {
        let root = Entity()
        root.name = "looking_glass"

        let lensCenterY: Float = 0.11
        let frameRadius = portalRadius + 0.028
        let innerRimRadius = portalRadius + 0.006
        let handleTopY = lensCenterY - innerRimRadius
        let handleLength: Float = 0.2
        let handleRadius: Float = 0.017
        let handleCenterY = handleTopY - (handleLength / 2)

        var manipulation = ManipulationComponent()
        manipulation.releaseBehavior = .stay
        manipulation.audioConfiguration = .none
        root.components.set(manipulation)
        root.components.set(InputTargetComponent())
        root.components.set(
            CollisionComponent(
                shapes: [.generateCapsule(height: 0.33, radius: frameRadius * 1.1)],
                filter: CollisionFilter(group: portalInteractionGroup, mask: .all)
            )
        )

        let frame = ModelEntity(
            mesh: .generateCylinder(height: 0.012, radius: frameRadius),
            materials: [simpleMaterial(.init(red: 0.64, green: 0.49, blue: 0.22, alpha: 1.0), metallic: true)]
        )
        frame.name = "glass_frame"
        frame.transform.rotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        frame.position = [0, lensCenterY, 0]
        root.addChild(frame)

        let innerBezel = ModelEntity(
            mesh: .generateCylinder(height: 0.006, radius: innerRimRadius),
            materials: [simpleMaterial(.init(red: 0.84, green: 0.73, blue: 0.44, alpha: 1.0), metallic: true)]
        )
        innerBezel.name = "glass_inner_bezel"
        innerBezel.transform.rotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        innerBezel.position = [0, lensCenterY, 0.004]
        root.addChild(innerBezel)

        let portalDiskFront = ModelEntity(
            mesh: .generateCylinder(height: 0.002, radius: portalRadius),
            materials: [PortalMaterial()]
        )
        portalDiskFront.name = "portal_disk_front"
        portalDiskFront.transform.rotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        portalDiskFront.position = [0, lensCenterY, 0.009]
        portalDiskFront.components.set(InputTargetComponent())
        portalDiskFront.components.set(
            CollisionComponent(
                shapes: [.generateBox(width: portalRadius * 2, height: 0.003, depth: portalRadius * 2)],
                filter: CollisionFilter(group: portalInteractionGroup, mask: .all)
            )
        )
        root.addChild(portalDiskFront)

        let portalDiskBack = ModelEntity(
            mesh: .generateCylinder(height: 0.002, radius: portalRadius),
            materials: [PortalMaterial()]
        )
        portalDiskBack.name = "portal_disk_back"
        portalDiskBack.transform.rotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        portalDiskBack.position = [0, lensCenterY, -0.009]
        portalDiskBack.components.set(InputTargetComponent())
        portalDiskBack.components.set(
            CollisionComponent(
                shapes: [.generateBox(width: portalRadius * 2, height: 0.003, depth: portalRadius * 2)],
                filter: CollisionFilter(group: portalInteractionGroup, mask: .all)
            )
        )
        root.addChild(portalDiskBack)

        let debugRing = ModelEntity(
            mesh: .generateCylinder(height: 0.003, radius: portalRadius + 0.01),
            materials: [unlitMaterial(.init(red: 0.27, green: 0.82, blue: 1.0, alpha: 0.22))]
        )
        debugRing.name = "portal_debug_ring"
        debugRing.transform.rotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        debugRing.position = [0, lensCenterY, 0.012]
        debugRing.isEnabled = false
        root.addChild(debugRing)

        let handle = ModelEntity(
            mesh: .generateCylinder(height: handleLength, radius: handleRadius),
            materials: [simpleMaterial(.init(red: 0.31, green: 0.17, blue: 0.08, alpha: 1.0), metallic: false)]
        )
        handle.name = "glass_handle_visual"
        handle.position = [0, handleCenterY, 0]
        root.addChild(handle)

        let handleCap = ModelEntity(
            mesh: .generateSphere(radius: 0.022),
            materials: [simpleMaterial(.init(red: 0.66, green: 0.51, blue: 0.2, alpha: 1.0), metallic: true)]
        )
        handleCap.name = "glass_handle_cap"
        handleCap.position = [0, handleCenterY - (handleLength / 2) - 0.014, 0]
        root.addChild(handleCap)

        let handleHitTarget = Entity()
        handleHitTarget.name = "glass_handle_hit_target"
        handleHitTarget.position = [0, handleCenterY - 0.02, 0]
        handleHitTarget.components.set(
            CollisionComponent(
                shapes: [.generateCapsule(height: 0.18, radius: 0.038)],
                filter: CollisionFilter(group: portalInteractionGroup, mask: .all)
            )
        )
        handleHitTarget.components.set(InputTargetComponent())
        handleHitTarget.components.set(ManipulationComponent.HitTarget(redirectedEntity: root))
        root.addChild(handleHitTarget)

        let homeTransform = Transform(
            scale: .one,
            rotation: simd_quatf(angle: -.pi / 11, axis: [1, 0, 0]),
            // Rest the handle base near the pedestal top so the glass is clearly visible.
            translation: [0, 0.95, 0.05]
        )

        root.transform = homeTransform

        return LookingGlassAssembly(
            root: root,
            handleHitTarget: handleHitTarget,
            portalDiskFront: portalDiskFront,
            portalDiskBack: portalDiskBack,
            debugRing: debugRing,
            homeTransform: homeTransform
        )
    }

    static func makePedestal() -> Entity {
        let root = Entity()
        root.name = "pedestal_root"
        // Keep the pedestal base on floor-level at session origin.
        root.position = [0, 0.0, -1.05]

        let base = ModelEntity(
            mesh: .generateCylinder(height: 0.62, radius: 0.18),
            materials: [simpleMaterial(.init(red: 0.18, green: 0.12, blue: 0.08, alpha: 1.0), metallic: false)]
        )
        base.position = [0, 0.31, 0]
        root.addChild(base)

        let collar = ModelEntity(
            mesh: .generateCylinder(height: 0.08, radius: 0.23),
            materials: [simpleMaterial(.init(red: 0.65, green: 0.5, blue: 0.22, alpha: 1.0), metallic: true)]
        )
        collar.position = [0, 0.62, 0]
        root.addChild(collar)

        let top = ModelEntity(
            mesh: .generateCylinder(height: 0.08, radius: 0.34),
            materials: [simpleMaterial(.init(red: 0.36, green: 0.21, blue: 0.11, alpha: 1.0), metallic: false)]
        )
        top.position = [0, 0.72, 0]
        root.addChild(top)

        let lip = ModelEntity(
            mesh: .generateCylinder(height: 0.04, radius: 0.36),
            materials: [simpleMaterial(.init(red: 0.72, green: 0.58, blue: 0.28, alpha: 1.0), metallic: true)]
        )
        lip.position = [0, 0.76, 0]
        root.addChild(lip)

        return root
    }

    static func makeCollectionSlotMarker(slotID: String) -> Entity {
        let marker = ModelEntity(
            mesh: .generateCylinder(height: 0.015, radius: 0.038),
            materials: [simpleMaterial(.init(red: 0.79, green: 0.67, blue: 0.37, alpha: 1.0), metallic: true)]
        )
        marker.name = "collection_slot_\(slotID)"
        return marker
    }

    static func makeWizardStudyEnvironment() -> Entity {
        let root = Entity()
        root.name = "wizard_study_environment"

        root.addChild(makeShelfBay(angleDegrees: -55, radius: 1.65))
        root.addChild(makeShelfBay(angleDegrees: 0, radius: 1.82))
        root.addChild(makeShelfBay(angleDegrees: 55, radius: 1.65))
        root.addChild(makeSideCabinet(angleDegrees: -118, radius: 1.7))
        root.addChild(makeSideCabinet(angleDegrees: 118, radius: 1.7))

        let desk = makeDesk()
        desk.position = [0, -0.56, -1.24]
        root.addChild(desk)

        let backAccent = ModelEntity(
            mesh: .generateSphere(radius: 0.18),
            materials: [unlitMaterial(.init(red: 0.98, green: 0.84, blue: 0.46, alpha: 0.22))]
        )
        backAccent.position = [0, 0.18, -2.05]
        root.addChild(backAccent)

        return root
    }

    static func makeTargetVisual(for assetID: String) -> Entity {
        if let loadedObject = loadBundledObject(for: assetID) {
            return loadedObject
        }

        switch assetID {
        case "feather_quill":
            return makeQuill()
        case "hourglass":
            return makeHourglass()
        case "crystal_ball":
            return makeCrystalBall()
        case "potion_bottle":
            return makePotionBottle()
        case "spell_book":
            return makeSpellBook()
        case "key":
            return makeKey()
        case "candle":
            return makeCandle()
        case "wand":
            return makeWand()
        case "moon_charm":
            return makeMoonCharm()
        case "tiny_dragon_figurine":
            return makeDragonFigurine()
        default:
            return ModelEntity(
                mesh: .generateBox(size: 0.12, cornerRadius: 0.01),
                materials: [simpleMaterial(.init(red: 0.66, green: 0.66, blue: 0.66, alpha: 1.0), metallic: false)]
            )
        }
    }

    static func makeSelectionHalo(radius: Float, color: UIColor) -> Entity {
        let halo = ModelEntity(
            mesh: .generateSphere(radius: max(radius * 1.12, 0.05)),
            materials: [unlitMaterial(color)]
        )
        return halo
    }

    static func makeSelectionBracket(radius: Float) -> Entity {
        let root = Entity()
        let bracketRadius = max(radius * 1.22, 0.06)
        let segmentLength = max(radius * 0.55, 0.04)
        let thickness = max(radius * 0.08, 0.004)
        let depth = thickness

        func makeSegment(size: SIMD3<Float>, position: SIMD3<Float>) -> ModelEntity {
            let segment = ModelEntity(
                mesh: .generateBox(size: size, cornerRadius: thickness * 0.5),
                materials: [unlitMaterial(.init(red: 0.98, green: 0.82, blue: 0.28, alpha: 0.9))]
            )
            segment.position = position
            return segment
        }

        root.addChild(makeSegment(size: [segmentLength, thickness, depth], position: [0, bracketRadius, 0]))
        root.addChild(makeSegment(size: [segmentLength, thickness, depth], position: [0, -bracketRadius, 0]))
        root.addChild(makeSegment(size: [thickness, segmentLength, depth], position: [bracketRadius, 0, 0]))
        root.addChild(makeSegment(size: [thickness, segmentLength, depth], position: [-bracketRadius, 0, 0]))
        return root
    }

    static func makeDebugBounds(radius: Float) -> Entity {
        let debug = ModelEntity(
            mesh: .generateSphere(radius: max(radius, 0.03)),
            materials: [unlitMaterial(.init(red: 0.1, green: 0.95, blue: 0.95, alpha: 0.16))]
        )
        return debug
    }

    static func simpleMaterial(_ color: UIColor, metallic: Bool) -> SimpleMaterial {
        SimpleMaterial(color: color, isMetallic: metallic)
    }

    static func unlitMaterial(_ color: UIColor) -> UnlitMaterial {
        UnlitMaterial(color: color)
    }

    private static func makeShelfBay(angleDegrees: Float, radius: Float) -> Entity {
        let root = Entity()
        root.position = circularPosition(radius: radius, angleDegrees: angleDegrees, y: -0.46)
        root.orientation = simd_quatf(angle: radians(180 - angleDegrees), axis: [0, 1, 0])

        let back = occludingBox(size: [0.88, 1.34, 0.12], color: .init(red: 0.28, green: 0.18, blue: 0.1, alpha: 1))
        back.position = [0, 0.67, 0]
        root.addChild(back)

        for y in stride(from: Float(0.28), through: 1.1, by: 0.28) {
            let shelf = occludingBox(size: [0.92, 0.04, 0.2], color: .init(red: 0.5, green: 0.34, blue: 0.2, alpha: 1))
            shelf.position = [0, y, 0.03]
            root.addChild(shelf)
        }

        for x in stride(from: Float(-0.33), through: 0.33, by: 0.16) {
            for y in [Float(0.3), 0.58, 0.86, 1.14] {
                let book = ModelEntity(
                    mesh: .generateBox(width: 0.06, height: 0.12 + Float.random(in: 0...0.06), depth: 0.12, cornerRadius: 0.008),
                    materials: [simpleMaterial(randomBookColor(seed: x + y), metallic: false)]
                )
                book.position = [x + Float.random(in: -0.015...0.015), y, 0.055]
                root.addChild(book)
            }
        }

        let candles = makeCandleCluster()
        candles.position = [0.26, 1.18, 0.08]
        root.addChild(candles)

        return root
    }

    private static func makeSideCabinet(angleDegrees: Float, radius: Float) -> Entity {
        let root = Entity()
        root.position = circularPosition(radius: radius, angleDegrees: angleDegrees, y: -0.7)
        root.orientation = simd_quatf(angle: radians(180 - angleDegrees), axis: [0, 1, 0])

        let body = occludingBox(size: [0.58, 0.88, 0.28], color: .init(red: 0.23, green: 0.15, blue: 0.1, alpha: 1))
        body.position = [0, 0.44, 0]
        root.addChild(body)

        let top = ModelEntity(
            mesh: .generateBox(width: 0.62, height: 0.03, depth: 0.3, cornerRadius: 0.01),
            materials: [simpleMaterial(.init(red: 0.68, green: 0.52, blue: 0.24, alpha: 1), metallic: true)]
        )
        top.position = [0, 0.9, 0]
        root.addChild(top)

        return root
    }

    private static func makeDesk() -> Entity {
        let root = Entity()
        root.name = "study_desk"

        let top = occludingBox(size: [0.98, 0.06, 0.42], color: .init(red: 0.31, green: 0.2, blue: 0.12, alpha: 1))
        top.position = [0, 0.32, 0]
        root.addChild(top)

        for x in [-0.42, 0.42] as [Float] {
            for z in [-0.15, 0.15] as [Float] {
                let leg = occludingBox(size: [0.05, 0.32, 0.05], color: .init(red: 0.24, green: 0.15, blue: 0.08, alpha: 1))
                leg.position = [x, 0.16, z]
                root.addChild(leg)
            }
        }

        let books = ModelEntity(
            mesh: .generateBox(width: 0.18, height: 0.1, depth: 0.12, cornerRadius: 0.01),
            materials: [simpleMaterial(.init(red: 0.45, green: 0.19, blue: 0.17, alpha: 1), metallic: false)]
        )
        books.position = [-0.18, 0.4, -0.03]
        root.addChild(books)

        let orbStand = ModelEntity(
            mesh: .generateCylinder(height: 0.08, radius: 0.05),
            materials: [simpleMaterial(.init(red: 0.61, green: 0.46, blue: 0.2, alpha: 1), metallic: true)]
        )
        orbStand.position = [0.24, 0.39, 0]
        root.addChild(orbStand)

        let glow = ModelEntity(
            mesh: .generateSphere(radius: 0.08),
            materials: [unlitMaterial(.init(red: 0.65, green: 0.82, blue: 1.0, alpha: 0.38))]
        )
        glow.position = [0.24, 0.49, 0]
        root.addChild(glow)

        let candleCluster = makeCandleCluster()
        candleCluster.position = [0.08, 0.39, 0.08]
        root.addChild(candleCluster)

        return root
    }

    private static func makeCandleCluster() -> Entity {
        let root = Entity()
        for (index, height) in [Float(0.12), 0.18, 0.15].enumerated() {
            let x = Float(index - 1) * 0.05
            let candle = ModelEntity(
                mesh: .generateCylinder(height: height, radius: 0.025),
                materials: [simpleMaterial(.init(red: 0.93, green: 0.87, blue: 0.72, alpha: 1), metallic: false)]
            )
            candle.position = [x, height / 2, 0]
            root.addChild(candle)

            let flame = ModelEntity(
                mesh: .generateCone(height: 0.05, radius: 0.014),
                materials: [unlitMaterial(.init(red: 1.0, green: 0.73, blue: 0.19, alpha: 0.95))]
            )
            flame.position = [x, height + 0.025, 0]
            root.addChild(flame)
        }
        return root
    }

    private static func makeQuill() -> Entity {
        let root = Entity()
        let shaft = ModelEntity(
            mesh: .generateCylinder(height: 0.22, radius: 0.008),
            materials: [simpleMaterial(.init(red: 0.67, green: 0.49, blue: 0.24, alpha: 1), metallic: false)]
        )
        shaft.orientation = simd_quatf(angle: .pi / 3, axis: [0, 0, 1])
        root.addChild(shaft)

        let feather = ModelEntity(
            mesh: .generateCone(height: 0.13, radius: 0.04),
            materials: [simpleMaterial(.init(red: 0.82, green: 0.8, blue: 0.73, alpha: 1), metallic: false)]
        )
        feather.position = [-0.05, 0.08, 0]
        feather.orientation = simd_quatf(angle: -.pi / 4, axis: [0, 0, 1])
        root.addChild(feather)
        return root
    }

    private static func makeHourglass() -> Entity {
        let root = Entity()
        for y in [Float(0.09), -0.09] {
            let cone = ModelEntity(
                mesh: .generateCone(height: 0.16, radius: 0.06),
                materials: [simpleMaterial(.init(red: 0.78, green: 0.62, blue: 0.4, alpha: 1), metallic: false)]
            )
            cone.position = [0, y, 0]
            cone.orientation = simd_quatf(angle: y > 0 ? .pi : 0, axis: [1, 0, 0])
            root.addChild(cone)
        }
        for x in [-0.05, 0.05] as [Float] {
            let rod = ModelEntity(
                mesh: .generateCylinder(height: 0.28, radius: 0.01),
                materials: [simpleMaterial(.init(red: 0.68, green: 0.53, blue: 0.24, alpha: 1), metallic: true)]
            )
            rod.position = [x, 0, 0]
            root.addChild(rod)
        }
        return root
    }

    private static func makeCrystalBall() -> Entity {
        let root = Entity()
        let stand = ModelEntity(
            mesh: .generateCylinder(height: 0.06, radius: 0.05),
            materials: [simpleMaterial(.init(red: 0.63, green: 0.47, blue: 0.2, alpha: 1), metallic: true)]
        )
        stand.position = [0, -0.05, 0]
        root.addChild(stand)

        let orb = ModelEntity(
            mesh: .generateSphere(radius: 0.08),
            materials: [unlitMaterial(.init(red: 0.56, green: 0.78, blue: 1.0, alpha: 0.75))]
        )
        orb.position = [0, 0.05, 0]
        root.addChild(orb)
        return root
    }

    private static func makePotionBottle() -> Entity {
        let root = Entity()
        let body = ModelEntity(
            mesh: .generateCylinder(height: 0.18, radius: 0.05),
            materials: [unlitMaterial(.init(red: 0.64, green: 0.29, blue: 0.88, alpha: 0.78))]
        )
        root.addChild(body)

        let neck = ModelEntity(
            mesh: .generateCylinder(height: 0.08, radius: 0.02),
            materials: [simpleMaterial(.init(red: 0.76, green: 0.63, blue: 0.42, alpha: 1), metallic: false)]
        )
        neck.position = [0, 0.12, 0]
        root.addChild(neck)

        let cork = ModelEntity(
            mesh: .generateBox(width: 0.03, height: 0.02, depth: 0.03, cornerRadius: 0.005),
            materials: [simpleMaterial(.init(red: 0.44, green: 0.26, blue: 0.13, alpha: 1), metallic: false)]
        )
        cork.position = [0, 0.17, 0]
        root.addChild(cork)
        return root
    }

    private static func makeSpellBook() -> Entity {
        let root = Entity()
        let cover = ModelEntity(
            mesh: .generateBox(width: 0.16, height: 0.04, depth: 0.22, cornerRadius: 0.01),
            materials: [simpleMaterial(.init(red: 0.4, green: 0.14, blue: 0.17, alpha: 1), metallic: false)]
        )
        cover.orientation = simd_quatf(angle: -.pi / 7, axis: [1, 0, 0])
        root.addChild(cover)

        let strap = ModelEntity(
            mesh: .generateBox(width: 0.03, height: 0.045, depth: 0.22, cornerRadius: 0.003),
            materials: [simpleMaterial(.init(red: 0.73, green: 0.58, blue: 0.28, alpha: 1), metallic: true)]
        )
        strap.orientation = cover.orientation
        root.addChild(strap)
        return root
    }

    private static func makeKey() -> Entity {
        let root = Entity()
        let shaft = ModelEntity(
            mesh: .generateCylinder(height: 0.16, radius: 0.012),
            materials: [simpleMaterial(.init(red: 0.77, green: 0.63, blue: 0.29, alpha: 1), metallic: true)]
        )
        shaft.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
        shaft.position = [0.03, 0, 0]
        root.addChild(shaft)

        let head = ModelEntity(
            mesh: .generateSphere(radius: 0.04),
            materials: [simpleMaterial(.init(red: 0.8, green: 0.66, blue: 0.3, alpha: 1), metallic: true)]
        )
        head.position = [-0.05, 0, 0]
        root.addChild(head)

        for y in [-0.02, 0.02] as [Float] {
            let tooth = ModelEntity(
                mesh: .generateBox(width: 0.018, height: 0.04, depth: 0.014, cornerRadius: 0.003),
                materials: [simpleMaterial(.init(red: 0.8, green: 0.66, blue: 0.3, alpha: 1), metallic: true)]
            )
            tooth.position = [0.11, y, 0]
            root.addChild(tooth)
        }
        return root
    }

    private static func makeCandle() -> Entity {
        let root = Entity()
        let body = ModelEntity(
            mesh: .generateCylinder(height: 0.18, radius: 0.035),
            materials: [simpleMaterial(.init(red: 0.95, green: 0.9, blue: 0.77, alpha: 1), metallic: false)]
        )
        root.addChild(body)

        let flame = ModelEntity(
            mesh: .generateCone(height: 0.06, radius: 0.018),
            materials: [unlitMaterial(.init(red: 1.0, green: 0.74, blue: 0.18, alpha: 0.95))]
        )
        flame.position = [0, 0.12, 0]
        root.addChild(flame)
        return root
    }

    private static func makeWand() -> Entity {
        let root = Entity()
        let shaft = ModelEntity(
            mesh: .generateCylinder(height: 0.28, radius: 0.008),
            materials: [simpleMaterial(.init(red: 0.37, green: 0.19, blue: 0.08, alpha: 1), metallic: false)]
        )
        shaft.orientation = simd_quatf(angle: .pi / 4, axis: [0, 0, 1])
        root.addChild(shaft)

        let tip = ModelEntity(
            mesh: .generateSphere(radius: 0.022),
            materials: [unlitMaterial(.init(red: 0.98, green: 0.86, blue: 0.48, alpha: 0.9))]
        )
        tip.position = [-0.09, 0.1, 0]
        root.addChild(tip)
        return root
    }

    private static func makeMoonCharm() -> Entity {
        let root = Entity()
        for (index, offset) in [
            SIMD3<Float>(-0.03, 0.05, 0),
            SIMD3<Float>(0.0, 0.07, 0),
            SIMD3<Float>(0.03, 0.05, 0),
            SIMD3<Float>(0.05, 0.01, 0),
            SIMD3<Float>(0.03, -0.03, 0),
            SIMD3<Float>(0.0, -0.05, 0)
        ].enumerated() {
            let bead = ModelEntity(
                mesh: .generateSphere(radius: index == 2 ? 0.032 : 0.028),
                materials: [simpleMaterial(.init(red: 0.85, green: 0.73, blue: 0.38, alpha: 1), metallic: true)]
            )
            bead.position = offset
            root.addChild(bead)
        }
        return root
    }

    private static func makeDragonFigurine() -> Entity {
        let root = Entity()

        let body = ModelEntity(
            mesh: .generateCone(height: 0.16, radius: 0.06),
            materials: [simpleMaterial(.init(red: 0.14, green: 0.56, blue: 0.39, alpha: 1), metallic: false)]
        )
        body.orientation = simd_quatf(angle: -.pi / 2, axis: [0, 0, 1])
        root.addChild(body)

        let head = ModelEntity(
            mesh: .generateSphere(radius: 0.04),
            materials: [simpleMaterial(.init(red: 0.16, green: 0.62, blue: 0.43, alpha: 1), metallic: false)]
        )
        head.position = [0.08, 0.03, 0]
        root.addChild(head)

        for x in [-0.01, 0.01] as [Float] {
            let wing = ModelEntity(
                mesh: .generateCone(height: 0.11, radius: 0.05),
                materials: [simpleMaterial(.init(red: 0.21, green: 0.71, blue: 0.52, alpha: 1), metallic: false)]
            )
            wing.position = [0, 0.05, x * 4]
            wing.orientation = simd_quatf(angle: x < 0 ? -.pi / 3 : .pi / 3, axis: [0, 0, 1])
            root.addChild(wing)
        }

        return root
    }

    private static func occludingBox(size: SIMD3<Float>, color: UIColor) -> ModelEntity {
        let entity = ModelEntity(
            mesh: .generateBox(size: size, cornerRadius: 0.01),
            materials: [simpleMaterial(color, metallic: false)]
        )
        entity.components.set(
            CollisionComponent(
                shapes: [.generateBox(size: size)],
                filter: CollisionFilter(group: hiddenOccluderGroup, mask: .all)
            )
        )
        return entity
    }

    private static func circularPosition(radius: Float, angleDegrees: Float, y: Float) -> SIMD3<Float> {
        let angle = radians(angleDegrees)
        return [sin(angle) * radius, y, -cos(angle) * radius]
    }

    private static func radians(_ degrees: Float) -> Float {
        degrees * (.pi / 180)
    }

    private static func randomBookColor(seed: Float) -> UIColor {
        let colors: [UIColor] = [
            .init(red: 0.47, green: 0.17, blue: 0.15, alpha: 1),
            .init(red: 0.16, green: 0.34, blue: 0.54, alpha: 1),
            .init(red: 0.28, green: 0.44, blue: 0.22, alpha: 1),
            .init(red: 0.52, green: 0.34, blue: 0.14, alpha: 1)
        ]
        let index = Int(abs(seed * 1000).rounded()) % colors.count
        return colors[index]
    }

    private static func loadBundledObject(for assetID: String) -> Entity? {
        let explicitName = objectResourceNameByAssetID[assetID]
        let candidates = [explicitName, assetID]
            .compactMap { $0 }
            .uniqued()

        for resourceName in candidates {
            if let cachedTemplate = loadedObjectTemplates[resourceName] {
                let clone = cachedTemplate.clone(recursive: true)
                clone.name = "asset:\(assetID)"
                let scale = bundledObjectScale * (bundledObjectScaleMultiplierByAssetID[assetID] ?? 1.0)
                clone.scale *= SIMD3<Float>(repeating: scale)
                return clone
            }

            let urls = [
                Bundle.main.url(forResource: resourceName, withExtension: "usdz", subdirectory: "Objects"),
                Bundle.main.url(forResource: resourceName, withExtension: "usdz", subdirectory: "objects"),
                Bundle.main.url(forResource: resourceName, withExtension: "usdz")
            ].compactMap { $0 }

            for url in urls {
                if let loaded = (try? Entity.load(contentsOf: url)) ?? (try? ModelEntity.loadModel(contentsOf: url)) {
                    loadedObjectTemplates[resourceName] = loaded
                    let clone = loaded.clone(recursive: true)
                    clone.name = "asset:\(assetID)"
                    let scale = bundledObjectScale * (bundledObjectScaleMultiplierByAssetID[assetID] ?? 1.0)
                    clone.scale *= SIMD3<Float>(repeating: scale)
                    return clone
                }
            }
        }

        if missingObjectNames.insert(assetID).inserted {
            print("GlassVision: missing or failed USDZ load for assetID '\(assetID)'")
        }
        return nil
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
