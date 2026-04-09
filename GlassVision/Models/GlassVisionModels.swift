//
//  GlassVisionModels.swift
//  GlassVision
//
//  Created by Codex on 4/9/26.
//

import Foundation
import RealityKit
import simd

enum PuzzleLaunchPath: String, Codable, CaseIterable, Sendable {
    case daily
    case library

    var title: String {
        switch self {
        case .daily:
            return "Daily Puzzle"
        case .library:
            return "Puzzle Select"
        }
    }
}

enum PuzzleDifficulty: String, Codable, Sendable {
    case easy
    case normal
    case hard

    var displayName: String {
        rawValue.capitalized
    }
}

struct PuzzleLaunchContext: Identifiable, Equatable, Sendable {
    let id: UUID
    let puzzleID: String
    let launchPath: PuzzleLaunchPath
    let dailyKey: String?

    init(
        id: UUID = UUID(),
        puzzleID: String,
        launchPath: PuzzleLaunchPath,
        dailyKey: String?
    ) {
        self.id = id
        self.puzzleID = puzzleID
        self.launchPath = launchPath
        self.dailyKey = dailyKey
    }
}

struct PuzzleDefinition: Codable, Identifiable, Hashable, Sendable {
    static let defaultPuzzleID = "wizard_study_001"

    let id: String
    let displayName: String
    let theme: String
    let environmentSceneID: String
    let difficulty: PuzzleDifficulty
    let targetItems: [TargetItemDefinition]
    let decoyItems: [TargetItemDefinition]
    let dailyAvailability: DailyAvailability
    let audioProfile: String
    let collectionSlotLayout: [CollectionSlotDefinition]
    let spawnRootID: String
    let portalProfileID: String
    let statsProfileID: String
}

struct DailyAvailability: Codable, Hashable, Sendable {
    let includedInDailyRotation: Bool
}

struct TargetItemDefinition: Codable, Identifiable, Hashable, Sendable {
    var id: String { itemID }

    let itemID: String
    let displayName: String
    let assetID: String
    let silhouetteAssetID: String
    let worldTransform: TransformDefinition
    let boundsProfile: BoundsProfile
    let selectionPriority: Int
    let pedestalSlotID: String
    let isDecoy: Bool
}

struct BoundsProfile: Codable, Hashable, Sendable {
    let radius: Float
    let minimumPortalOverlap: Float
}

struct CollectionSlotDefinition: Codable, Identifiable, Hashable, Sendable {
    var id: String { slotID }

    let slotID: String
    let position: SIMD3<Float>
    let rotation: SIMD4<Float>
    let scale: SIMD3<Float>
}

struct TransformDefinition: Codable, Hashable, Sendable {
    let position: SIMD3<Float>
    let rotation: SIMD4<Float>
    let scale: SIMD3<Float>

    var transform: Transform {
        let quaternion = simd_quatf(
            ix: rotation.x,
            iy: rotation.y,
            iz: rotation.z,
            r: rotation.w
        )
        return Transform(scale: scale, rotation: quaternion, translation: position)
    }
}

struct PuzzleLibraryEntry: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let theme: String
    let difficulty: PuzzleDifficulty
    let completionStatus: PuzzleStatRecord?
}

struct PuzzleStatRecord: Codable, Hashable, Sendable {
    var totalCompletions: Int
    var bestCompletionTime: TimeInterval?
    var mostRecentCompletionTime: TimeInterval?
}

struct StatsSnapshot: Codable, Hashable, Sendable {
    var totalPuzzleCompletions: Int
    var perPuzzle: [String: PuzzleStatRecord]
    var completedDailyKeys: Set<String>

    static let empty = StatsSnapshot(
        totalPuzzleCompletions: 0,
        perPuzzle: [:],
        completedDailyKeys: []
    )
}

struct CompletionSummary: Equatable, Sendable {
    let puzzleID: String
    let puzzleName: String
    let launchPath: PuzzleLaunchPath
    let elapsedTime: TimeInterval
    let foundCount: Int
    let dailyKey: String?
}

struct PortalEligibilitySnapshot: Equatable, Sendable {
    let targetID: String?
    let targetName: String?
    let overlapScore: Float
    let centerInsidePortal: Bool
    let passedOcclusion: Bool
    let isAlreadyFound: Bool
    let portalActive: Bool
}

extension TimeInterval {
    var glassVisionClockString: String {
        let totalSeconds = Int(self.rounded(.down))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let hundredths = Int((self - floor(self)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }
}
