//
//  AppModel.swift
//  GlassVision
//
//  Created by Max Caro on 4/9/26.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    let immersiveSpaceID = "ImmersiveSpace"

    @Published var immersiveSpaceState: ImmersiveSpaceState = .closed
    @Published var activeLaunchContext: PuzzleLaunchContext?
    @Published var selectedLibraryPuzzleID: String = PuzzleDefinition.defaultPuzzleID
    @Published var latestErrorMessage: String?
    @Published var sceneIsActive = true
    @Published var statsSnapshot: StatsSnapshot

    let repository: PuzzleRepository
    private let dailyResolver: DailyPuzzleResolver
    private let statsStore: StatsStore

    init() {
        let repository = PuzzleRepository()
        let dailyResolver = DailyPuzzleResolver()
        let statsStore = StatsStore()

        self.repository = repository
        self.dailyResolver = dailyResolver
        self.statsStore = statsStore
        self.statsSnapshot = statsStore.load()

        if let firstPuzzle = repository.loadAll().first {
            selectedLibraryPuzzleID = firstPuzzle.id
        }
    }

    var libraryEntries: [PuzzleLibraryEntry] {
        repository.libraryEntries(using: statsSnapshot)
    }

    var activePuzzleDefinition: PuzzleDefinition? {
        guard let puzzleID = activeLaunchContext?.puzzleID else {
            return nil
        }
        return repository.loadPuzzle(id: puzzleID)
    }

    var todaysDailyKey: String {
        dailyResolver.dailyKey(for: .now)
    }

    var isTodayDailyComplete: Bool {
        statsSnapshot.completedDailyKeys.contains(todaysDailyKey)
    }

    func prepareDailyLaunch(for date: Date = .now) {
        do {
            activeLaunchContext = try dailyResolver.resolveLaunchContext(
                for: date,
                repository: repository
            )
            latestErrorMessage = nil
        } catch {
            activeLaunchContext = nil
            latestErrorMessage = error.localizedDescription
        }
    }

    func prepareLibraryLaunch() {
        guard repository.loadPuzzle(id: selectedLibraryPuzzleID) != nil else {
            latestErrorMessage = "The selected puzzle could not be loaded."
            activeLaunchContext = nil
            return
        }

        activeLaunchContext = PuzzleLaunchContext(
            puzzleID: selectedLibraryPuzzleID,
            launchPath: .library,
            dailyKey: nil
        )
        latestErrorMessage = nil
    }

    func handleImmersiveOpened() {
        immersiveSpaceState = .open
    }

    func handleImmersiveClosed() {
        immersiveSpaceState = .closed
        activeLaunchContext = nil
    }

    func recordCompletion(_ summary: CompletionSummary) {
        statsSnapshot = statsStore.recordCompletion(summary, into: statsSnapshot)
    }
}
