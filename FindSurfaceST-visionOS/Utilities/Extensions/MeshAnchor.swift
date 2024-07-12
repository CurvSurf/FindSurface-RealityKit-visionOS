//
//  MeshAnchor.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import ARKit
import simd
import Algorithms

extension MeshAnchor {
    
    var pointcloud: [simd_float3] {
        let transform = originFromAnchorTransform
        return geometry.vertices.asSimdFloat3().map {
            simd_make_float3(transform * simd_float4($0, 1))
        }
    }
    
    var faces: [simd_uint3] {
        
        let faceBuffer = geometry.faces.buffer
        let faceCount = geometry.faces.count
        let bytesPerIndex = geometry.faces.bytesPerIndex
        return (0..<faceCount * 3).map { index in
            faceBuffer.contents()
                .advanced(by: index * bytesPerIndex)
                .assumingMemoryBound(to: UInt32.self)
                .pointee
        }.chunks(ofCount: 3).map {
            let i0 = $0.startIndex
            let i1 = i0 + 1
            let i2 = i0 + 2
            return simd_uint3($0[i0], $0[i1], $0[i2])
        }
    }
}
