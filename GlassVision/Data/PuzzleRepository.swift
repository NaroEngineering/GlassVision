//
//  PuzzleRepository.swift
//  GlassVision
//
//  Created by Codex on 4/9/26.
//

import Foundation

struct PuzzleRepository {
    private let decoder = JSONDecoder()
    private let fallbackObjectAssetIDs = [
        "CrystalLotus",
        "GemCoin",
        "goldendice",
        "MagmaExplosion",
        "ufo",
        "car-coupe-blue",
        "car-coupe-green",
        "car-coupe-citrus"
    ]

    func loadAll() -> [PuzzleDefinition] {
        let urls = puzzleDefinitionURLs()

        return urls.compactMap { url in
            guard let data = try? Data(contentsOf: url) else {
                return nil
            }

            return try? decoder.decode(PuzzleDefinition.self, from: data)
        }
        .sorted { $0.displayName < $1.displayName }
    }

    func loadPuzzle(id: String) -> PuzzleDefinition? {
        if id.hasPrefix(PuzzleDefinition.randomObjectsPrefix) {
            return makeRandomObjectsPuzzle(id: id)
        }
        return loadAll().first(where: { $0.id == id })
    }

    func libraryEntries(using snapshot: StatsSnapshot) -> [PuzzleLibraryEntry] {
        loadAll().map { puzzle in
            PuzzleLibraryEntry(
                id: puzzle.id,
                title: puzzle.displayName,
                theme: puzzle.theme,
                difficulty: puzzle.difficulty,
                completionStatus: snapshot.perPuzzle[puzzle.id]
            )
        }
    }

    private func puzzleDefinitionURLs() -> [URL] {
        let bundle = Bundle.main
        let byPreferredSubdirectory = bundle.urls(forResourcesWithExtension: "json", subdirectory: "Puzzles") ?? []
        if !byPreferredSubdirectory.isEmpty {
            return byPreferredSubdirectory
        }

        // Fallback: some build setups flatten folder resources into the bundle root.
        return bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
    }

    private func makeRandomObjectsPuzzle(id: String) -> PuzzleDefinition? {
        guard let basePuzzle = loadAll().first(where: { $0.id == PuzzleDefinition.defaultPuzzleID }) ?? loadAll().first else {
            return nil
        }

        let objectAssetIDs = bundledObjectAssetIDs()
        guard !objectAssetIDs.isEmpty else {
            return basePuzzle
        }

        var generator = SeededGenerator(seed: deterministicSeed(from: id))
        let shuffledAssetIDs = objectAssetIDs.shuffled(using: &generator)
        let mappedTargets = basePuzzle.targetItems.enumerated().map { index, target in
            let assetID = shuffledAssetIDs[index % shuffledAssetIDs.count]
            return TargetItemDefinition(
                itemID: target.itemID,
                displayName: readableName(from: assetID),
                assetID: assetID,
                silhouetteAssetID: target.silhouetteAssetID,
                worldTransform: target.worldTransform,
                boundsProfile: target.boundsProfile,
                selectionPriority: target.selectionPriority,
                pedestalSlotID: target.pedestalSlotID,
                isDecoy: target.isDecoy
            )
        }

        return PuzzleDefinition(
            id: id,
            displayName: "Random Objects",
            theme: "random_objects",
            environmentSceneID: basePuzzle.environmentSceneID,
            difficulty: basePuzzle.difficulty,
            targetItems: mappedTargets,
            decoyItems: [],
            dailyAvailability: basePuzzle.dailyAvailability,
            audioProfile: basePuzzle.audioProfile,
            collectionSlotLayout: basePuzzle.collectionSlotLayout,
            spawnRootID: basePuzzle.spawnRootID,
            portalProfileID: basePuzzle.portalProfileID,
            statsProfileID: basePuzzle.statsProfileID
        )
    }

    private func bundledObjectAssetIDs() -> [String] {
        let bundle = Bundle.main
        let fromObjectsUpper = bundle.urls(forResourcesWithExtension: "usdz", subdirectory: "Objects") ?? []
        let fromObjectsLower = bundle.urls(forResourcesWithExtension: "usdz", subdirectory: "objects") ?? []
        let fromRoot = bundle.urls(forResourcesWithExtension: "usdz", subdirectory: nil) ?? []

        let discovered = (fromObjectsUpper + fromObjectsLower + fromRoot)
            .map { $0.deletingPathExtension().lastPathComponent }
            .filter { !$0.isEmpty }

        if !discovered.isEmpty {
            return Array(Set(discovered)).sorted()
        }

        // Fallback for packaging setups where runtime discovery is unreliable.
        return fallbackObjectAssetIDs
    }

    private func readableName(from assetID: String) -> String {
        assetID
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private func deterministicSeed(from string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return hash == 0 ? 0x9E3779B97F4A7C15 : hash
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
