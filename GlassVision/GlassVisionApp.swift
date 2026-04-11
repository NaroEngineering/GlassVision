//
//  GlassVisionApp.swift
//  GlassVision
//
//  Created by Max Caro on 4/9/26.
//

import SwiftUI

@main
struct GlassVisionApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environmentObject(appModel)
                .onAppear {
                    appModel.handleImmersiveOpened()
                }
                .onDisappear {
                    appModel.handleImmersiveClosed()
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
