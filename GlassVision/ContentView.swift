//
//  ContentView.swift
//  GlassVision
//
//  Created by Max Caro on 4/9/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase
    @State private var pendingLaunchContext: PuzzleLaunchContext?
    private let sectionCornerRadius: CGFloat = 14

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerSection
                    startSection
                    if appModel.immersiveSpaceState == .inTransition {
                        transitionStatusSection
                    }
                    mainSection

                    if let latestErrorMessage = appModel.latestErrorMessage {
                        Label(latestErrorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.body)
                            .foregroundStyle(.orange)
                            .padding(12)
                            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: sectionCornerRadius, style: .continuous))
                    }
                }
                .padding(18)
                .frame(maxWidth: 920, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .navigationTitle("Glass Vision")
        }
        .ornament(visibility: appModel.immersiveSpaceState == .open ? .visible : .hidden, attachmentAnchor: .scene(.bottom)) {
            Button("Close Session") {
                Task { @MainActor in
                    await closeImmersiveSpace()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassBackgroundEffect()
        }
        .onChange(of: scenePhase) { _, newValue in
            appModel.sceneIsActive = newValue == .active
        }
        .onChange(of: appModel.immersiveSpaceState) { _, newValue in
            guard newValue == .closed, let queuedContext = pendingLaunchContext else {
                return
            }

            pendingLaunchContext = nil
            appModel.activeLaunchContext = queuedContext
            Task { @MainActor in
                await openImmersiveIfPossible()
            }
        }
    }

    private var selectedEntry: PuzzleLibraryEntry? {
        appModel.libraryEntries.first { $0.id == appModel.selectedLibraryPuzzleID }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Find Hidden Objects")
                .font(.largeTitle.weight(.semibold))

            Text("Use the looking glass to reveal hidden items and complete each scene.")
                .font(.title3.weight(.regular))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let selectedEntry {
                HStack(spacing: 10) {
                    Label(selectedEntry.title, systemImage: "sparkles")
                    Text(selectedEntry.difficulty.displayName)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline.weight(.semibold))
                .padding(.top, 4)
            }
        }
        .padding(18)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: sectionCornerRadius, style: .continuous))
    }

    private var startSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start Playing")
                .font(.title3.weight(.semibold))

            HStack(spacing: 10) {
                Button {
                    Task { @MainActor in
                        await launchDaily()
                    }
                } label: {
                    Label("Play Daily Puzzle", systemImage: "sun.max.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(appModel.immersiveSpaceState == .inTransition)

                Button {
                    Task { @MainActor in
                        await launchSelectedPuzzle()
                    }
                } label: {
                    Label("Play Selected Puzzle", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(appModel.immersiveSpaceState == .inTransition)
            }

            HStack(spacing: 12) {
                Text("Daily: \(appModel.isTodayDailyComplete ? "Completed" : "Available")")
                Text("Selected: \(selectedEntry?.title ?? "None")")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: sectionCornerRadius, style: .continuous))
    }

    private var transitionStatusSection: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.regular)
            Text("Loading immersive experience...")
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .padding(14)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: sectionCornerRadius, style: .continuous))
    }

    private var mainSection: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 14) {
                librarySection
                progressPanel
            }
            VStack(alignment: .leading, spacing: 14) {
                librarySection
                progressPanel
            }
        }
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Puzzle Library")
                .font(.title3.weight(.semibold))
            ForEach(appModel.libraryEntries) { entry in
                Button {
                    appModel.selectedLibraryPuzzleID = entry.id
                } label: {
                    puzzleRow(for: entry)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(appModel.selectedLibraryPuzzleID == entry.id ? .white.opacity(0.18) : .white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: sectionCornerRadius, style: .continuous))
    }

    private var progressPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Progress")
                .font(.title3.weight(.semibold))

            statRow(title: "Total Completions", value: "\(appModel.statsSnapshot.totalPuzzleCompletions)")
            statRow(title: "Today", value: appModel.isTodayDailyComplete ? "Completed" : "Not Completed")
            statRow(title: "Best Time", value: bestTimeText)
            statRow(title: "Selected", value: selectedEntry?.title ?? "None")

            if appModel.immersiveSpaceState == .open {
                Text("Session is active. Use the Close Session control below.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: 330, alignment: .leading)
        .padding(16)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: sectionCornerRadius, style: .continuous))
    }

    private func puzzleRow(for entry: PuzzleLibraryEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.body.weight(.semibold))
                Text("\(entry.theme.replacingOccurrences(of: "_", with: " ").capitalized) • \(entry.difficulty.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if appModel.selectedLibraryPuzzleID == entry.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
            if let status = entry.completionStatus {
                Text(status.bestCompletionTime?.glassVisionClockString ?? "--:--.--")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else {
                Text("New")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
            }
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }

    private var bestTimeText: String {
        guard let selectedID = selectedEntry?.id,
              let record = appModel.statsSnapshot.perPuzzle[selectedID],
              let best = record.bestCompletionTime else {
            return "--:--.--"
        }
        return best.glassVisionClockString
    }

    @MainActor
    private func launchDaily() async {
        appModel.prepareDailyLaunch()
        guard let launchContext = appModel.activeLaunchContext else {
            return
        }

        if appModel.immersiveSpaceState == .open || appModel.immersiveSpaceState == .inTransition {
            pendingLaunchContext = launchContext
            await closeImmersiveSpace()
        } else {
            await openImmersiveIfPossible()
        }
    }

    @MainActor
    private func launchSelectedPuzzle() async {
        appModel.prepareLibraryLaunch()
        guard let launchContext = appModel.activeLaunchContext else {
            return
        }

        if appModel.immersiveSpaceState == .open || appModel.immersiveSpaceState == .inTransition {
            pendingLaunchContext = launchContext
            await closeImmersiveSpace()
        } else {
            await openImmersiveIfPossible()
        }
    }

    @MainActor
    private func openImmersiveIfPossible() async {
        guard appModel.activeLaunchContext != nil else {
            return
        }

        guard appModel.immersiveSpaceState == .closed else {
            return
        }

        appModel.immersiveSpaceState = .inTransition
        switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
        case .opened:
            break
        case .userCancelled, .error:
            fallthrough
        @unknown default:
            appModel.handleImmersiveClosed()
            appModel.latestErrorMessage = "The immersive space could not be opened."
        }
    }

    @MainActor
    private func closeImmersiveSpace() async {
        guard appModel.immersiveSpaceState == .open else {
            return
        }

        appModel.immersiveSpaceState = .inTransition
        await dismissImmersiveSpace()

        if appModel.immersiveSpaceState == .inTransition {
            appModel.handleImmersiveClosed()
        }
    }
}
