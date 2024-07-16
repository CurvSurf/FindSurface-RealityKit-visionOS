//
//  PlaneEntity.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/25/24.
//

import Foundation
import RealityKit

@MainActor
final class PlaneEntity: GeometryEntity {
 
    enum Shape {
        case volume
        case surface
    }
    
    struct Intrinsics: Equatable {
        var width: Float
        var height: Float
        var outlineWidth: Float
        var shape: Shape
        init(width: Float = 1, height: Float = 1, outlineWidth: Float = 0.005, shape: Shape = .volume) {
            self.width = width
            self.height = height
            self.outlineWidth = outlineWidth
            self.shape = shape
        }
    }
    private(set) var intrinsics = Intrinsics()
    
    private let occlusion: ModelEntity
    private let surface: ModelEntity
    private let outline: ModelEntity
    
    convenience init(width: Float, height: Float, outlineWidth: Float = 0.005, shape: Shape = .volume) {
        self.init()
        update { intrinsics in
            intrinsics.width = width
            intrinsics.height = height
            intrinsics.outlineWidth = outlineWidth
            intrinsics.shape = shape
        }
    }
    
    required init() {
        
        let occlusion = {
            let mesh = MeshResource.generateVolumetricPlane(width: 1, height: 1, thickness: 0.0001)
            let material = OcclusionMaterial()
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let surface = {
            let mesh = MeshResource.generateVolumetricPlane(width: 1, height: 1, thickness: 0.002)
            let material = UnlitMaterial(color: .red.withAlphaComponent(0.2))
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let outline = {
            let mesh = MeshResource.generateVolumetricPlane(width: 1, height: 1, thickness: 0.001 + 0.0001, useClockwiseTriangleWinding: true)
            let material = UnlitMaterial(color: .black)
            let model = ModelEntity(mesh: mesh, materials: [material])
            let scale: Float = 1.0 + 0.005
            model.transform = Transform(scale: .init(scale, scale, 1))
            return model
        }()
        
        self.occlusion = occlusion
        self.surface = surface
        self.outline = outline
        super.init()
        
        addChild(occlusion)
        addChild(surface)
        addChild(outline)
        
        update(block: { _ in })
    }
    
    @MainActor
    func update(block: (inout Intrinsics) -> Void) {
        
        var intrinsics = self.intrinsics
        block(&intrinsics)
        
        guard intrinsics != self.intrinsics else { return }
        
        let w = intrinsics.width
        let h = intrinsics.height
        let outlineWidth = intrinsics.outlineWidth
        
        let scale = simd_float3(w, h, 1)
        let outlineScale = simd_float3(w + outlineWidth * 3, h + outlineWidth * 3, 1)
        
        occlusion.transform.scale = scale
        surface.transform.scale = scale
        outline.transform.scale = outlineScale
        
        if intrinsics.shape != self.intrinsics.shape {
            switch intrinsics.shape {
            case .volume:
                surface.model?.mesh = .generateVolumetricPlane(width: 1, height: 1, thickness: 0.002)
            case .surface:
                surface.model?.mesh = .generatePlane(width: 1, height: 1)
            }
        }
        
        self.intrinsics = intrinsics
    }
    
    override func enableOutline(_ visible: Bool) {
        occlusion.isEnabled = visible
        outline.isEnabled = visible
    }
}

