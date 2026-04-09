//
//  ImmersiveView.swift
//  GlassVision
//
//  Created by Max Caro on 4/9/26.
//

import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var runtime = GlassVisionRuntime()

    var body: some View {
        RealityView { content, attachments in
            await runtime.configureIfNeeded(content: &content, attachments: attachments, appModel: appModel)
        } update: { content, attachments in
            runtime.update(content: &content, attachments: attachments, appModel: appModel)
        } attachments: {
            Attachment(id: GlassVisionRuntime.AttachmentID.checklist) {
                ChecklistPanelView(runtime: runtime)
            }

            Attachment(id: GlassVisionRuntime.AttachmentID.debug) {
                DebugPanelView(runtime: runtime)
            }

            Attachment(id: GlassVisionRuntime.AttachmentID.completion) {
                CompletionPanelView(
                    runtime: runtime,
                    onReplay: {
                        runtime.reloadCurrentPuzzle()
                    },
                    onReturnToMenu: {
                        Task { @MainActor in
                            appModel.immersiveSpaceState = .inTransition
                            await dismissImmersiveSpace()
                        }
                    }
                )
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    runtime.handlePinchConfirmation(on: value.entity)
                }
        )
        .onDisappear {
            runtime.handleImmersiveDismissal()
        }
        .onChange(of: scenePhase) { _, newValue in
            runtime.handleScenePhaseChange(newValue)
            appModel.sceneIsActive = newValue == .active
        }
    }
}
