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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.09, blue: 0.06), Color(red: 0.28, green: 0.18, blue: 0.11)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    launchCards
                    librarySection
                    statsSection
                    if let latestErrorMessage = appModel.latestErrorMessage {
                        Text(latestErrorMessage)
                            .font(.callout)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(28)
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            appModel.sceneIsActive = newValue == .active
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Glass Vision")
                .font(.system(size: 42, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text("Mixed-reality hidden objects through a handheld magical lens. MVP ships with Wizard Study as both the daily puzzle and the first library puzzle.")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var launchCards: some View {
        HStack(spacing: 18) {
            launchCard(
                title: "Daily Puzzle",
                subtitle: appModel.isTodayDailyComplete ? "Completed today" : "Local daily based on the device date",
                buttonTitle: appModel.immersiveSpaceState == .open ? "Close Active Session" : "Play Daily Puzzle",
                action: {
                    if appModel.immersiveSpaceState == .open {
                        await closeImmersiveSpace()
                    } else {
                        appModel.prepareDailyLaunch()
                        await openImmersiveIfPossible()
                    }
                }
            )

            launchCard(
                title: "Puzzle Select",
                subtitle: "Choose authored puzzles from the library",
                buttonTitle: "Play Selected Puzzle",
                action: {
                    appModel.prepareLibraryLaunch()
                    await openImmersiveIfPossible()
                }
            )
        }
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Puzzle Library")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            ForEach(appModel.libraryEntries) { entry in
                Button {
                    appModel.selectedLibraryPuzzleID = entry.id
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.title)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("\(entry.theme.replacingOccurrences(of: "_", with: " ").capitalized) • \(entry.difficulty.displayName)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.72))
                        }

                        Spacer()

                        if let status = entry.completionStatus {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Best \(status.bestCompletionTime?.glassVisionClockString ?? "--:--.--")")
                                Text("\(status.totalCompletions) completions")
                            }
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.86))
                        } else {
                            Text("New")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.yellow)
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(appModel.selectedLibraryPuzzleID == entry.id ? Color.white.opacity(0.16) : Color.white.opacity(0.07))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(appModel.selectedLibraryPuzzleID == entry.id ? Color.yellow.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 18) {
            statBlock(title: "Total Completions", value: "\(appModel.statsSnapshot.totalPuzzleCompletions)")
            statBlock(title: "Daily Status", value: appModel.isTodayDailyComplete ? "Done" : "Open")
            statBlock(
                title: "Selected Puzzle",
                value: appModel.libraryEntries.first(where: { $0.id == appModel.selectedLibraryPuzzleID })?.title ?? "Wizard Study"
            )
        }
    }

    private func launchCard(
        title: String,
        subtitle: String,
        buttonTitle: String,
        action: @escaping @MainActor () async -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.74))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button(buttonTitle) {
                Task { @MainActor in
                    await action()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.yellow.opacity(0.9))
            .disabled(appModel.immersiveSpaceState == .inTransition)
        }
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .padding(22)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
            appModel.immersiveSpaceState = .closed
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
    }
}
