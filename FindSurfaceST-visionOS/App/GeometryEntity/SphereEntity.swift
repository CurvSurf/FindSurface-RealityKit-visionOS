//
//  SphereEntity.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/25/24.
//

import Foundation
import RealityKit

@MainActor
final class SphereEntity: GeometryEntity {
    
    struct Intrinsics: Equatable {
        var radius: Float
        var outlineWidth: Float
        init(radius: Float = 1, outlineWidth: Float = 0.005) {
            self.radius = radius
            self.outlineWidth = outlineWidth
        }
    }
    private(set) var intrinsics = Intrinsics()
    
    private let occlusion: ModelEntity
    private let wireframe: ModelEntity
    private let surface: ModelEntity
    private let outline: ModelEntity
    
    convenience init(radius: Float, outlineWidth: Float = 0.005) {
        self.init()
        update { intrinsics in
            intrinsics.radius = radius
            intrinsics.outlineWidth = outlineWidth
        }
    }
    
    override func enableOutline(_ visible: Bool) {
        occlusion.isEnabled = visible
        wireframe.isEnabled = visible
        outline.isEnabled = visible
    }
    
    required init() {
        
        let occlusion = {
            let mesh = MeshResource.generateLowPolySphere(radius: 1 - 0.0001)
            let material = OcclusionMaterial()
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let wireframe = {
            let mesh = MeshResource.generateLowPolySphere(radius: 1)
            var material = UnlitMaterial(color: .black)
            material.triangleFillMode = .lines
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let surface = {
            let mesh = MeshResource.generateLowPolySphere(radius: 1)
            let material = UnlitMaterial(color: .green.withAlphaComponent(0.2))
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let outline = {
            let mesh = MeshResource.generateLowPolySphere(radius: 1, useClockwiseTriangleWinding: true)
            let material = UnlitMaterial(color: .black)
            let model = ModelEntity(mesh: mesh, materials: [material])
            model.transform = Transform(scale: .init(repeating: 1.0 + 0.005))
            return model
        }()
        
        self.occlusion = occlusion
        self.wireframe = wireframe
        self.surface = surface
        self.outline = outline
        super.init()
        
        addChild(occlusion)
        addChild(wireframe)
        addChild(surface)
        addChild(outline)
        
        update(block: { _ in })
    }
    
    @MainActor
    func update(block: (inout Intrinsics) -> Void) {
        
        var intrinsics = self.intrinsics
        block(&intrinsics)
        
        guard intrinsics != self.intrinsics else { return }
        
        let radius = intrinsics.radius
        let outlineWidth = intrinsics.outlineWidth
        
        let scale = simd_float3(repeating: radius)
        let outlineScale = simd_float3(repeating: radius + outlineWidth)
        
        occlusion.transform.scale = scale
        wireframe.transform.scale = scale
        surface.transform.scale = scale
        outline.transform.scale = outlineScale
        
        self.intrinsics = intrinsics
    }
}
