//
//  ChecklistPanelView.swift
//  GlassVision
//
//  Created by Codex on 4/9/26.
//

import SwiftUI

struct ChecklistPanelView: View {
    @ObservedObject var runtime: GlassVisionRuntime
    let onReturnToMenu: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(runtime.puzzle?.displayName ?? "Wizard Study")
                        .font(.headline)
                    Text("Checklist")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(runtime.foundCount) / \(runtime.requiredCount)")
                    .font(.headline.monospacedDigit())
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                ForEach(runtime.checklistItems) { item in
                    ChecklistItemCell(
                        title: item.displayName,
                        symbolName: item.symbolName,
                        isFound: item.isFound
                    )
                }
            }

            HStack {
                Text(runtime.elapsedTime.glassVisionClockString)
                    .font(.body.monospacedDigit().weight(.semibold))
                Spacer()
                Text(runtime.launchPathTitle)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Button("Back To Menu", action: onReturnToMenu)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(18)
        .frame(width: 360)
        .glassBackgroundEffect()
    }
}

private struct ChecklistItemCell: View {
    let title: String
    let symbolName: String
    let isFound: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.title3.weight(.bold))
                .frame(width: 34, height: 34)
                .foregroundStyle(isFound ? .yellow : .primary)
                .background(
                    Circle()
                        .fill(isFound ? Color.yellow.opacity(0.2) : Color.black.opacity(0.12))
                )
                .symbolRenderingMode(.monochrome)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                Text(isFound ? "Found" : "Hidden")
                    .font(.caption2)
                    .foregroundStyle(isFound ? .yellow : .secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isFound ? Color.yellow.opacity(0.12) : Color.white.opacity(0.06))
        )
    }
}
