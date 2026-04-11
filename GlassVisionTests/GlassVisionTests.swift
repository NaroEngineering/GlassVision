//
//  GlassVisionTests.swift
//  GlassVisionTests
//
//  Created by Max Caro on 4/9/26.
//

import Foundation
import Testing
@testable import GlassVision

@MainActor
struct GlassVisionTests {
    @Test func dailyResolverUsesLocalDateKeyShape() async throws {
        let resolver = DailyPuzzleResolver()
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(year: 2026, month: 4, day: 9))!

        #expect(resolver.dailyKey(for: date) == "2026-04-09")
    }

    @Test func statsStoreTracksBestAndMostRecentTimes() async throws {
        let store = StatsStore()
        let firstSummary = CompletionSummary(
            puzzleID: "wizard_study_001",
            puzzleName: "Wizard Study",
            launchPath: .daily,
            elapsedTime: 96.4,
            foundCount: 10,
            dailyKey: "2026-04-09"
        )
        let secondSummary = CompletionSummary(
            puzzleID: "wizard_study_001",
            puzzleName: "Wizard Study",
            launchPath: .library,
            elapsedTime: 88.2,
            foundCount: 10,
            dailyKey: nil
        )

        let firstSnapshot = store.recordCompletion(firstSummary, into: .empty)
        let secondSnapshot = store.recordCompletion(secondSummary, into: firstSnapshot)

        #expect(secondSnapshot.totalPuzzleCompletions >= 2)
        #expect(secondSnapshot.perPuzzle["wizard_study_001"]?.bestCompletionTime == 88.2)
        #expect(secondSnapshot.perPuzzle["wizard_study_001"]?.mostRecentCompletionTime == 88.2)
        #expect(secondSnapshot.completedDailyKeys.contains("2026-04-09"))
    }

    @Test func puzzleDefinitionDefaultIDIsStable() async throws {
        #expect(PuzzleDefinition.defaultPuzzleID == "wizard_study_001")
    }

    @Test func dailyResolverResolvesWizardStudyForMVP() async throws {
        let resolver = DailyPuzzleResolver()
        let repository = PuzzleRepository()
        let date = Date(timeIntervalSince1970: 0)

        let context = try resolver.resolveLaunchContext(
            for: date,
            repository: repository
        )

        let expectedID = PuzzleDefinition.randomObjectsPuzzleID(for: resolver.dailyKey(for: date))
        #expect(context.launchPath == .daily)
        #expect(context.puzzleID == expectedID)
        #expect(repository.loadPuzzle(id: context.puzzleID) != nil)
    }

    @Test func wizardStudyPuzzleContainsTenTargets() async throws {
        let repository = PuzzleRepository()
        let puzzle = try #require(repository.loadPuzzle(id: "wizard_study_001"))

        #expect(puzzle.targetItems.count == 10)
        #expect(puzzle.decoyItems.isEmpty)
        #expect(Set(puzzle.targetItems.map(\.pedestalSlotID)).count == 10)
    }
}
