//
//  TrackerLocation.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import ARKit

enum TrackerLocation: CaseIterable {
    case thumbTip
    case indexFingerTip
    case middleFingerTip
    case ringFingerTip
    case littleFingerTip
    case wrist
}

extension TrackerLocation {
    init(_ jointName: HandSkeleton.JointName) {
        switch jointName {
        case .thumbTip:                     fallthrough
        case .thumbKnuckle:                 fallthrough
        case .thumbIntermediateTip:         fallthrough
        case .thumbIntermediateBase:        self = .thumbTip
            
        case .indexFingerMetacarpal:        fallthrough
        case .indexFingerKnuckle:           fallthrough
        case .indexFingerIntermediateBase:  fallthrough
        case .indexFingerIntermediateTip:   fallthrough
        case .indexFingerTip:               self = .indexFingerTip
        
        case .middleFingerMetacarpal:       fallthrough
        case .middleFingerKnuckle:          fallthrough
        case .middleFingerIntermediateBase: fallthrough
        case .middleFingerIntermediateTip:  fallthrough
        case .middleFingerTip:              self = .middleFingerTip
        
        case .ringFingerMetacarpal:         fallthrough
        case .ringFingerKnuckle:            fallthrough
        case .ringFingerIntermediateBase:   fallthrough
        case .ringFingerIntermediateTip:    fallthrough
        case .ringFingerTip:                self = .ringFingerTip
        
        case .littleFingerMetacarpal:       fallthrough
        case .littleFingerKnuckle:          fallthrough
        case .littleFingerIntermediateBase: fallthrough
        case .littleFingerIntermediateTip:  fallthrough
        case .littleFingerTip:              self = .littleFingerTip
        
        case .forearmWrist:                 fallthrough
        case .forearmArm:                   fallthrough
        case .wrist:                        self = .wrist
        @unknown default:                   fatalError()
        }
    }
    
    var jointName: HandSkeleton.JointName {
        switch self {
        case .thumbTip:         return .thumbTip
        case .indexFingerTip:   return .indexFingerTip
        case .middleFingerTip:  return .middleFingerTip
        case .ringFingerTip:    return .ringFingerTip
        case .littleFingerTip:  return .littleFingerTip
        case .wrist:            return .wrist
        }
    }
}
