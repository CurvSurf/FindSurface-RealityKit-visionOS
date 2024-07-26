//
//  Hand.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import simd
import ARKit
import RealityKit

final class Hands: Entity {
    
    var leftHand: Hand
    var rightHand: Hand
    
    required init() {
        self.leftHand = Hand()
        self.rightHand = Hand()
        super.init()
        
        self.addChild(leftHand)
        self.addChild(rightHand)
    }
    
    subscript(_ chirality: HandAnchor.Chirality) -> Hand {
        get {
            switch chirality {
            case .left:     return leftHand
            case .right:    return rightHand
            }
        }
        set {
            switch chirality {
            case .left:     leftHand = newValue
            case .right:    rightHand = newValue
            }
        }
    }
}

final class Hand: Entity {
    
    var thumbTip: ModelEntity
    var indexFingerTip: ModelEntity
    var middleFingerTip: ModelEntity
    var ringFingerTip: ModelEntity
    var littleFingerTip: ModelEntity
    var wrist: ModelEntity
    
    required init() {
        
        let fingerTipMesh = MeshResource.generateSphere(name: "", radius: 0.005)
        let wristMesh = MeshResource.generateCylinder(height: 0.02, radius: 0.05)
        
        let thumbMat = UnlitMaterial(color: .red)
        let indexFingerMat = UnlitMaterial(color: .orange)
        let middleFingerMat = UnlitMaterial(color: .yellow)
        let ringFingerMat = UnlitMaterial(color: .green)
        let littleFingerMat = UnlitMaterial(color: .blue)
        let wristMat = UnlitMaterial(color: .purple)
        
        let thumbTip = ModelEntity(mesh: fingerTipMesh, materials: [thumbMat])
        let indexFingerTip = ModelEntity(mesh: fingerTipMesh, materials: [indexFingerMat])
        let middleFingerTip = ModelEntity(mesh: fingerTipMesh, materials: [middleFingerMat])
        let ringFingerTip = ModelEntity(mesh: fingerTipMesh, materials: [ringFingerMat])
        let littleFingerTip = ModelEntity(mesh: fingerTipMesh, materials: [littleFingerMat])
        let wrist = ModelEntity(mesh: wristMesh, materials: [wristMat])
        
        thumbTip.isEnabled = false
        indexFingerTip.isEnabled = false
        middleFingerTip.isEnabled = false
        ringFingerTip.isEnabled = false
        littleFingerTip.isEnabled = false
        wrist.isEnabled = false
        
        self.thumbTip = thumbTip
        self.indexFingerTip = indexFingerTip
        self.middleFingerTip = middleFingerTip
        self.ringFingerTip = ringFingerTip
        self.littleFingerTip = littleFingerTip
        self.wrist = wrist
        
        super.init()
        
        self.addChild(thumbTip)
        self.addChild(indexFingerTip)
        self.addChild(middleFingerTip)
        self.addChild(ringFingerTip)
        self.addChild(littleFingerTip)
        self.addChild(wrist)
        
        self.components.set(OpacityComponent(opacity: 0))
    }
    
    subscript(_ location: TrackerLocation) -> ModelEntity {
        get {
            switch location {
            case .thumbTip:         return thumbTip
            case .indexFingerTip:   return indexFingerTip
            case .middleFingerTip:  return middleFingerTip
            case .ringFingerTip:    return ringFingerTip
            case .littleFingerTip:  return littleFingerTip
            case .wrist:            return wrist
            }
        }
        set {
            switch location {
            case .thumbTip:         thumbTip = newValue
            case .indexFingerTip:   indexFingerTip = newValue
            case .middleFingerTip:  middleFingerTip = newValue
            case .ringFingerTip:    ringFingerTip = newValue
            case .littleFingerTip:  littleFingerTip = newValue
            case .wrist:            wrist = newValue
            }
        }
    }
    
    func contacts(_ first: TrackerLocation, _ second: TrackerLocation) -> Bool {
        let firstFinger = self[first]
        let secondFinger = self[second]
        return firstFinger.isEnabled && secondFinger.isEnabled && distance(firstFinger.position, secondFinger.position) < 0.01
    }
}
