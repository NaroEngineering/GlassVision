//
//  StatsStore.swift
//  GlassVision
//
//  Created by Codex on 4/9/26.
//

import Foundation

struct StatsStore {
    private let defaultsKey = "GlassVision.StatsSnapshot"

    func load() -> StatsSnapshot {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let snapshot = try? JSONDecoder().decode(StatsSnapshot.self, from: data) else {
            return .empty
        }

        return snapshot
    }

    func recordCompletion(
        _ summary: CompletionSummary,
        into snapshot: StatsSnapshot
    ) -> StatsSnapshot {
        var updated = snapshot
        updated.totalPuzzleCompletions += 1

        var perPuzzle = updated.perPuzzle[summary.puzzleID] ?? PuzzleStatRecord(
            totalCompletions: 0,
            bestCompletionTime: nil,
            mostRecentCompletionTime: nil
        )
        perPuzzle.totalCompletions += 1
        perPuzzle.mostRecentCompletionTime = summary.elapsedTime
        if let existingBest = perPuzzle.bestCompletionTime {
            perPuzzle.bestCompletionTime = min(existingBest, summary.elapsedTime)
        } else {
            perPuzzle.bestCompletionTime = summary.elapsedTime
        }
        updated.perPuzzle[summary.puzzleID] = perPuzzle

        if summary.launchPath == .daily, let dailyKey = summary.dailyKey {
            updated.completedDailyKeys.insert(dailyKey)
        }

        persist(updated)
        return updated
    }

    private func persist(_ snapshot: StatsSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
