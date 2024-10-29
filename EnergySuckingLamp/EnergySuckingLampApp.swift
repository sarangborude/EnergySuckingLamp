//
//  EnergySuckingLampApp.swift
//  EnergySuckingLamp
//
//  Created by Sarang Borude on 10/17/24.
//

import SwiftUI
import RealityKitContent

@main
struct EnergySuckingLampApp: App {

    @State private var appModel = AppModel()

    let bleViewModel = BLEViewModel()
    init() {
        AttractionSystem.registerSystem()
        OrbComponent.registerComponent()
        EnergySuckerComponent.registerComponent()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .environment(bleViewModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .environment(bleViewModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
