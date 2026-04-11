//
//  DebugPanelView.swift
//  GlassVision
//
//  Created by Codex on 4/9/26.
//

import SwiftUI

struct DebugPanelView: View {
    @ObservedObject var runtime: GlassVisionRuntime

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Look Target")
                .font(.headline)

            Toggle("Portal Circle", isOn: binding(\.showPortalCircle))
            Toggle("Projected Bounds", isOn: binding(\.showProjectedBounds))
            Toggle("Gaze Target", isOn: binding(\.showGazeTarget))
            Toggle("Eligible Target", isOn: binding(\.showEligibleTarget))
            Toggle("Slot IDs", isOn: binding(\.showPedestalSlotIDs))

            Divider()

            Text("Targeted: \(runtime.lastTargetedEntityName)")
            Text("Gaze: \(runtime.currentGazeTargetName)")
            Text("Eligible: \(runtime.currentEligibleTargetName)")
            Text("Armed: \(runtime.currentArmedTargetName)")
            Text("Eligible State: \(runtime.currentEligibility?.targetID == nil ? "No" : "Yes")")
            Text("Overlap: \(runtime.currentOverlapText)")
            Text("Occlusion: \(runtime.currentEligibility?.passedOcclusion == true ? "Clear" : "Blocked")")
            Text("Already Found: \(runtime.currentEligibility?.isAlreadyFound == true ? "Yes" : "No")")
            Text("Portal: \(runtime.isPortalVisible ? "Active" : "Idle")")
            Text("Slot: \(runtime.lastAssignedSlotID)")
            Text("Tracking: \(runtime.trackingStateText)")
            Text("Audio: \(runtime.lastAudioCueName)")
            Text("Feedback: \(runtime.latestFeedbackMessage)")

            Divider()

            Button("Force Collect Current Target") {
                runtime.forceCollectCurrentTarget()
            }
            .buttonStyle(.borderedProminent)

            Button("Force Complete Puzzle") {
                runtime.forceCompletePuzzle()
            }
            .buttonStyle(.bordered)

            Button("Jump To Puzzle") {
                runtime.reloadCurrentPuzzle()
            }
            .buttonStyle(.bordered)
        }
        .font(.caption)
        .padding(16)
        .frame(width: 300, alignment: .leading)
        .glassBackgroundEffect()
    }

    private func binding(_ keyPath: WritableKeyPath<GlassVisionRuntime.DebugOptions, Bool>) -> Binding<Bool> {
        Binding(
            get: {
                runtime.debugOptions[keyPath: keyPath]
            },
            set: { newValue in
                var updated = runtime.debugOptions
                updated[keyPath: keyPath] = newValue
                runtime.debugOptions = updated
            }
        )
    }
}
