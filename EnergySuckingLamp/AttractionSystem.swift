//
//  File.swift
//  Energy Sucking Lamp
//
//  Created by Sarang Borude on 8/7/24.
//

import RealityKit
import RealityKitContent
//import Combine
import UIKit
import SwiftUI

class AttractionSystem: System {
    
    let energySuckerQuery = EntityQuery(where: .has(EnergySuckerComponent.self))
    let orbQuery = EntityQuery(where: .has(OrbComponent.self))
    let particleEmitterQuery = EntityQuery(where: .has(ParticleEmitterComponent.self))
    
    var energySuckerEntity = Entity()
    var mainParticleEntity = Entity()
    
    let distanceThreshold:Float = 0.6
    
    var hasFoundEnergySucker = false
    
    
    required init(scene: RealityKit.Scene) {
        Task {
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                // Keep in mind that the ParticleEmitter is not a child of the Orb in Reality Composer Pro scene.
                if let particleEntity = immersiveContentEntity.findEntity(named: "ParticleEmitter") {
                    mainParticleEntity = particleEntity
                }
            }
        }
    }
    
    func update(context: SceneUpdateContext) {
        // check the distance from the object to get attracted to and if it is a certain threshold then get attracted to it.
        
        if(!hasFoundEnergySucker) {
            context.scene.performQuery(energySuckerQuery).forEach { energySucker in
                energySuckerEntity = energySucker
                hasFoundEnergySucker = true
            }
        }

        // set the attraction center for the particle emitters to the energySuckerEntity
        // We use the context.entities(matching:,updatingSystemWhen:) method instead of perform query because perform query will make your entities not update.
        let particleEmitterEntities = context.entities(matching: particleEmitterQuery, updatingSystemWhen: .rendering)
        var particleEntityCount = 0
        for particleEmitterEntity in particleEmitterEntities {
            particleEntityCount += 1
            if var particleEmitter = particleEmitterEntity.components[ParticleEmitterComponent.self] {
                let energySuckerPos = energySuckerEntity.position(relativeTo: particleEmitterEntity)
                particleEmitter.mainEmitter.attractionCenter = energySuckerPos
                particleEmitterEntity.components[ParticleEmitterComponent.self] = particleEmitter
            } else {
                fatalError("Cannot find particle emitter")
            }
        }
        print("Particle entities detected: \(particleEntityCount)")
        
        let orbEntities = context.entities(matching: orbQuery, updatingSystemWhen: .rendering)
        
        for orb in orbEntities {
            
            let pos = energySuckerEntity.position(relativeTo: nil)
            let orbPos = orb.position(relativeTo: nil)
            let distance = distance(orbPos, pos)
            if(distance < distanceThreshold) {
                orb.components[OrbComponent.self] = .none
                destroy(orb: orb)
            }
        }
    }
    
    func destroy(orb: Entity) {
        print("Destroying \(orb.name)")
        
        var mat = orb.components[ModelComponent.self]?.materials.first as! ShaderGraphMaterial
        
        guard let param = mat.getParameter(name: "EmissiveColor") else {
            fatalError("cannot get the material parameter")
        }
        
        
        var color = UIColor.white
        switch param {
        case .color(let colorParameter):
            color = UIColor(cgColor: colorParameter)
        default:
            break
        }
        
        let ciColor = CIColor(color: color)
        
        let r = ciColor.red * 256
        let g = ciColor.green * 256
        let b = ciColor.blue * 256
        
        BLEViewModel.writeToDevice(value: "\(Int(r)),\(Int(g)),\(Int(b))")
        
        // what would happen if you don't clone the entity rather just play the animation of existing entity.
        
        // start the particle animation
        let particleSystem = mainParticleEntity.clone(recursive: true)
        particleSystem.name = "ParticleSystem"
        orb.addChild(particleSystem)
        
        // set the color here
        var particleEmitterComponent = particleSystem.components[ParticleEmitterComponent.self]!
        particleEmitterComponent.mainEmitter.color = .constant(.single(color))
        particleSystem.components[ParticleEmitterComponent.self] = particleEmitterComponent
        
        
        // Animate the disintegration of the orb
        let frameRate: TimeInterval = 1.0/60.0 // 60FPS
        let duration: TimeInterval = 2
        let targetValue: Float = 1
        let totalFrames = Int(duration / frameRate)
        var currentFrame = 0
        var disintegrate: Float = 0
        
        
        
        Timer.scheduledTimer(withTimeInterval: frameRate, repeats: true, block: { timer in
            currentFrame += 1
            let progress = Float(currentFrame) / Float(totalFrames)
            
            disintegrate = progress * targetValue
            
            // set the parameter value and then assign the material back to the model component
            do {
                try mat.setParameter(name: "Disintegration", value: .float(disintegrate))
                orb.components[ModelComponent.self]?.materials = [mat]
            }
            catch {
                print(error.localizedDescription)
            }
            
            if currentFrame >= totalFrames {
                timer.invalidate()
                //Adding a delay for removal of orb so the particle system can live a little longer
                Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                    orb.removeFromParent()
                }
            }
        })
    }
}
