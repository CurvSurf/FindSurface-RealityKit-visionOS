//
//  DeviceAnchor.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import ARKit

extension DeviceAnchor {
    
    var position: simd_float3 {
        originFromAnchorTransform.position
    }
    
    var backward: simd_float3 {
        originFromAnchorTransform.basisZ
    }
    
    var forward: simd_float3 {
        -originFromAnchorTransform.basisZ
    }
    
    var right: simd_float3 {
        originFromAnchorTransform.basisX
    }
    
    var left: simd_float3 {
        -originFromAnchorTransform.basisX
    }
    
    var up: simd_float3 {
        originFromAnchorTransform.basisY
    }
    
    var down: simd_float3 {
        -originFromAnchorTransform.basisY
    }
}
