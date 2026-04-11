//
//  DailyPuzzleResolver.swift
//  GlassVision
//
//  Created by Codex on 4/9/26.
//

import Foundation

struct DailyPuzzleResolver {
    enum ResolutionError: LocalizedError {
        case noPuzzlesAvailable

        var errorDescription: String? {
            switch self {
            case .noPuzzlesAvailable:
                return "No local puzzles are available for the daily puzzle."
            }
        }
    }

    func dailyKey(for date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    func resolveLaunchContext(
        for date: Date,
        repository: PuzzleRepository
    ) throws -> PuzzleLaunchContext {
        let key = dailyKey(for: date)
        let randomPuzzleID = PuzzleDefinition.randomObjectsPuzzleID(for: key)

        guard repository.loadPuzzle(id: randomPuzzleID) != nil else {
            throw ResolutionError.noPuzzlesAvailable
        }

        return PuzzleLaunchContext(
            puzzleID: randomPuzzleID,
            launchPath: .daily,
            dailyKey: key
        )
    }
}
