//
//  SeedAreaIndicator.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import simd
import RealityKit

@MainActor
final class SeedAreaIndicator: Entity {
    
    required init() {
        let mesh = MeshResource.generateCylinder(height: 0.001, radius: 1.0)
        let materials = [SimpleMaterial(color: .blue.withAlphaComponent(0.3), isMetallic: false)]
        
        super.init()
        self.name = "Seed Area Indicator"
        self.components.set(ModelComponent(mesh: mesh, materials: materials))
    }
    
    var radius: Float = 1.0 {
        didSet {
            updateTransform()
        }
    }
    
    var normal: simd_float3 = .init(0, 1, 0) {
        didSet {
            updateTransform()
        }
    }
    
    private func updateTransform() {
        let scale = simd_float4x4.init(diagonal: .init(radius, 1, radius, 1))
        let orientation = simd_float4x4.extrinsics(yAxis: normal)
        let translation = position
        transform = Transform(matrix: orientation * scale)
        position = translation
    }
}
