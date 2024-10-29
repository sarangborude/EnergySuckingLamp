//
//  ContentView.swift
//  EnergySuckingLamp
//
//  Created by Sarang Borude on 10/17/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @Environment(BLEViewModel.self) private var bleViewModel
    
    var body: some View {
        VStack {
            Circle()
                .frame(width: 50, height: 50)
                .foregroundColor(BLEViewModel.isPeripheralConnected ? Color.blue : Color.gray)
            
            Model3D(named: "Scene", bundle: realityKitContentBundle)
                .padding(.bottom, 50)

            Text("Hello, world!")

            ToggleImmersiveSpaceButton()
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
