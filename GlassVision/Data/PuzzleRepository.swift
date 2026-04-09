//
//  PuzzleRepository.swift
//  GlassVision
//
//  Created by Codex on 4/9/26.
//

import Foundation

struct PuzzleRepository {
    private let decoder = JSONDecoder()

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
        loadAll().first(where: { $0.id == id })
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
}
