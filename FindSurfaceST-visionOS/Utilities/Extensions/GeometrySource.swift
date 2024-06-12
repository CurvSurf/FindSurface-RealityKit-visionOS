//
//  GeometrySource.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import simd
import Algorithms
import ARKit

extension GeometrySource {
    
    func asSimdFloat3() -> [simd_float3] {
        precondition(componentsPerVector == 3)
        let floatCount = count * 3
        let pointer = buffer.contents().bindMemory(to: Float.self, capacity: floatCount)
        let buffer = UnsafeBufferPointer(start: pointer, count: floatCount)
            .evenlyChunked(in: count)
            .map { values in
                simd_float3(values[values.startIndex],
                            values[values.startIndex + 1],
                            values[values.startIndex + 2])
            }
        return Array(buffer)
    }
}



