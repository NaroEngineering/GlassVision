//
//  CompletionPanelView.swift
//  GlassVision
//
//  Created by Codex on 4/9/26.
//

import SwiftUI

struct CompletionPanelView: View {
    @ObservedObject var runtime: GlassVisionRuntime
    let onReplay: () -> Void
    let onReturnToMenu: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Puzzle Complete")
                .font(.title2.weight(.bold))

            Text(runtime.completionTitle)
                .font(.headline)
            Text("\(runtime.foundCount) / \(runtime.requiredCount) found")
                .font(.subheadline.weight(.semibold))
            Text("Time \(runtime.elapsedTime.glassVisionClockString)")
                .font(.body.monospacedDigit())
            Text(runtime.launchPathTitle)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Replay", action: onReplay)
                    .buttonStyle(.borderedProminent)
                Button("Return To Menu", action: onReturnToMenu)
                    .buttonStyle(.bordered)
            }
        }
        .padding(22)
        .frame(width: 300, alignment: .leading)
        .glassBackgroundEffect()
    }
}
