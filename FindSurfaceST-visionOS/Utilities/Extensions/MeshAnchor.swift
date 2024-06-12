//
//  MeshAnchor.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import ARKit

extension MeshAnchor {
    
    var pointcloud: [simd_float3] {
        let transform = originFromAnchorTransform
        return geometry.vertices.asSimdFloat3().map {
            simd_make_float3(transform * simd_float4($0, 1))
        }
    }
}
