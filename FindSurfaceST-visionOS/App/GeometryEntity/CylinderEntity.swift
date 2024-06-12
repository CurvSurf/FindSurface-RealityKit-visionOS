//
//  CylinderEntity.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/25/24.
//

import Foundation
import RealityKit

@MainActor
final class CylinderEntity: GeometryEntity {
    
    enum Shape: Equatable {
        case volume
        case surface
    }
    
    struct Intrinsics: Equatable {
        var radius: Float
        var height: Float
        var outlineWidth: Float
        var shape: Shape
        init(radius: Float = 1, height: Float = 1, outlineWidth: Float = 0.005, shape: Shape = .volume) {
            self.radius = radius
            self.height = height
            self.outlineWidth = outlineWidth
            self.shape = shape
        }
    }
    private var intrinsics = Intrinsics()
    
    private let occlusion: ModelEntity
    private let wireframe: ModelEntity
    private let surface: ModelEntity
    private let outline: ModelEntity
    
    convenience init(radius: Float, height: Float, outlineWidth: Float = 0.005, shape: Shape = .volume) {
        self.init()
        update { intrinsics in
            intrinsics.radius = radius
            intrinsics.height = height
            intrinsics.outlineWidth = outlineWidth
            intrinsics.shape = shape
        }
    }
    
    override func enableOutline(_ visible: Bool) {
        occlusion.isEnabled = visible
        wireframe.isEnabled = visible
        outline.isEnabled = visible
    }
    
    required init() {
        
        let occlusion = {
            let mesh = MeshResource.generateCylinder(radius: Float(1 - 0.0001), height: Float(1 - 0.0002))
            let material = OcclusionMaterial()
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let wireframe = {
            let mesh = MeshResource.generateCylinder(radius: 1, height: 1)
            var material = UnlitMaterial(color: .black)
            material.triangleFillMode = .lines
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let surface = {
            let mesh = MeshResource.generateCylinder(radius: 1, height: 1)
            let material = UnlitMaterial(color: .purple.withAlphaComponent(0.2))
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let outline = {
            let mesh = MeshResource.generateCylinder(radius: 1, height: 1, useClockwiseTriangleWinding: true)
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
        let height = intrinsics.height
        let outlineWidth = intrinsics.outlineWidth
        
        let scale = simd_float3(radius, height, radius)
        let outlineScale = simd_float3(radius + outlineWidth, height + outlineWidth * 2, radius + outlineWidth)
        
        occlusion.transform.scale = scale
        wireframe.transform.scale = scale
        surface.transform.scale = scale
        outline.transform.scale = outlineScale
        
        if intrinsics.shape != self.intrinsics.shape {
            switch intrinsics.shape {
            case .volume:
                occlusion.model?.mesh = .generateCylinder(radius: Float(1 - 0.0001), height: Float(1 - 0.0002))
                let mesh = MeshResource.generateCylinder(radius: 1, height: 1)
                wireframe.model?.mesh = mesh
                surface.model?.mesh = mesh
                outline.model?.mesh = .generateCylinder(radius: 1, height: 1, useClockwiseTriangleWinding: true)
                
            case .surface:
                occlusion.model?.mesh = .generateVolumetricCylindricalSurface(radius: radius - 0.0001, height: height, thickness: 0.0001)
                let mesh = MeshResource.generateCylindricalSurface(radius: radius, height: height)
                wireframe.model?.mesh = mesh
                surface.model?.mesh = mesh
                outline.model?.mesh = .generateVolumetricCylindricalSurface(radius: radius, height: height, thickness: outlineWidth, useClockwiseTriangleWinding: true)
                occlusion.transform.scale = .one
                wireframe.transform.scale = .one
                surface.transform.scale = .one
                outline.transform.scale = .one
            }
        }
        
        self.intrinsics = intrinsics
    }
}
