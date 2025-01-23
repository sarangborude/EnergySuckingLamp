//
//  ImmersiveView.swift
//  EnergySuckingLamp
//
//  Created by Sarang Borude on 10/17/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    
    let configuration = SpatialTrackingSession.Configuration(tracking: [.hand])
    let session = SpatialTrackingSession()
    
    @Environment(BLEViewModel.self) private var bleViewModel
    @State private var orb = Entity()
    
    let orbColors: [UIColor] = [.red, .green, .blue, .yellow, .cyan, .orange, .magenta]
    
    
    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                
                if let orb = immersiveContentEntity.findEntity(named: "Orb") {
                    self.orb = orb
                }
                
                
                let rightHandEntity = AnchorEntity(.hand(.right, location: .palm))
                //let energySuckerEntity = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [SimpleMaterial(color: .green, isMetallic: false)])
                let energySuckerEntity = Entity()
                energySuckerEntity.components.set(EnergySuckerComponent())
                
                energySuckerEntity.position = [0, 0.1, 0]
                rightHandEntity.addChild(energySuckerEntity)
                content.add(rightHandEntity)
                
                //create multiple orbs
                
                for i in 0 ..< 7 {
                    let orbClone = orb.clone(recursive: true)
                    orbClone.name = "Orb_\(i)";
                    
                    //set position of orb in meters
                    orbClone.position = [
                        Float.random(in: -1 ... 1),
                        Float.random(in: 0.5 ... 1.5),
                        Float.random(in: -2 ... -1)
                    ]
                    let color = orbColors[i % orbColors.count]
                    
                    //get material of the orb and set the color
                    var mat = orbClone.components[ModelComponent.self]?.materials.first as! ShaderGraphMaterial
                    do {
                        try mat.setParameter(name: "EmissiveColor", value: .color(color))
                        orbClone.components[ModelComponent.self]?.materials = [mat]
                    }
                    catch {
                        print(error.localizedDescription)
                    }
                    
                    content.add(orbClone)
                }
            }
        }
        .gesture(
            DragGesture()
                .targetedToEntity(where: .has(OrbComponent.self))
                .onChanged({ value in
                    value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
                })
        )
        .task {
            if let unavailableCapabilities = await session.run(configuration) {
                if unavailableCapabilities.anchor.contains(.hand) {
                    print("Access to hand data failed")
                }
                else {
                    print("All is well with hand tracking")
                }
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
