//
//  CylinderEntity.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/25/24.
//

import Foundation
import RealityKit

fileprivate let cylinderOcclusionDepth: Float = 0.0001
fileprivate let occlusionMaterials = [OcclusionMaterial()]
fileprivate let wireframeMaterials = {
    var material = UnlitMaterial(color: .black)
    material.triangleFillMode = .lines
    return [material]
}()
fileprivate let surfaceMaterials = [UnlitMaterial(color: .purple.withAlphaComponent(0.2))]
fileprivate let outlineMaterials = [UnlitMaterial(color: .black)]

@MainActor
final class CylinderEntity: GeometryEntity {
    
    enum Shape: Equatable, Hashable, CaseIterable {
        case volume
        case surface
    }
    
    struct Intrinsics: Equatable {
        var radius: Float
        var length: Float
        var outlineWidth: Float
        var shape: Shape
        var subdivision: CylinderSubdivision
        init(radius: Float = 1,
             length: Float = 1,
             outlineWidth: Float = 0.005,
             shape: Shape = .volume,
             subdivision: ConeSubdivision = .both(36, 3)) {
            self.radius = radius
            self.length = length
            self.outlineWidth = outlineWidth
            self.shape = shape
            self.subdivision = subdivision
        }
    }
    private(set) var intrinsics: Intrinsics
    
    private let occlusion: ModelEntity
    private let wireframe: ModelEntity
    private let surface: ModelEntity
    private let outline: ModelEntity
    
    required init() {
        
        let intrinsics = Intrinsics()
        let dummy = MeshResource.generatePlane(width: 1, height: 1)
        let occlusion = ModelEntity(mesh: dummy, materials: occlusionMaterials)
        let wireframe = ModelEntity(mesh: dummy, materials: wireframeMaterials)
        let surface = ModelEntity(mesh: dummy, materials: surfaceMaterials)
        let outline = ModelEntity(mesh: dummy, materials: outlineMaterials)
        updateModelEntities(intrinsics, occlusion, wireframe, surface, outline)
        
        self.intrinsics = intrinsics
        self.occlusion = occlusion
        self.wireframe = wireframe
        self.surface = surface
        self.outline = outline
        super.init()
        
        addChild(occlusion)
        addChild(wireframe)
        addChild(surface)
        addChild(outline)
        
        #if SUPPORT_DEBUG_GESTURE
        let meshPoints = Submesh.generateCylindricalSurface(
            radius: 0.5,
            length: 1.0,
            subdivision: .radial(intrinsics.subdivision)).positions
        components.set(CollisionComponent(shapes: [.generateConvex(from: meshPoints)]))
        components.set(InputTargetComponent())
        components.set(DebugGestureComponent())
        #endif
    }
    
    convenience init(radius: Float,
                     length: Float,
                     outlineWidth: Float = 0.005,
                     shape: Shape = .volume,
                     subdivision: ConeSubdivision = .both(36, 3)) {
        self.init()
        update { intrinsics in
            intrinsics.radius = radius
            intrinsics.length = length
            intrinsics.outlineWidth = outlineWidth
            intrinsics.shape = shape
            intrinsics.subdivision = subdivision
        }
    }
    
    @MainActor
    func update(block: (inout Intrinsics) -> Void) {
        
        var intrinsics = self.intrinsics
        block(&intrinsics)
        
        guard intrinsics != self.intrinsics else { return }
        defer { self.intrinsics = intrinsics }
        
        let radius = intrinsics.radius
        let length = intrinsics.length
        let outlineWidth = intrinsics.outlineWidth
        let shape = intrinsics.shape
        let subdivision = intrinsics.subdivision
        
        guard shape == self.intrinsics.shape &&
        subdivision == self.intrinsics.subdivision else {
            updateModelEntities(intrinsics, occlusion, wireframe, surface, outline)
            return
        }
        
        let baseScale = simd_float3(radius, length, radius)
        
        switch shape {
        case .volume:
            
            occlusion.scale = baseScale - cylinderOcclusionDepth * .init(1, 2, 1)
            wireframe.scale = baseScale
            surface.scale = baseScale
            outline.scale = baseScale + outlineWidth * .init(1, 2, 1)
            
        case .surface:
            
            occlusion.model?.mesh = .generateVolumetricCylindricalSurface(
                radius: radius - cylinderOcclusionDepth - 0.00001,
                length: length,
                padding: cylinderOcclusionDepth,
                subdivision: .radial(subdivision)
            )
            occlusion.scale = .one
            
            wireframe.scale = baseScale
            surface.scale = baseScale
            
            outline.model?.mesh = .generateVolumetricCylindricalSurface(
                radius: radius,
                length: length,
                padding: outlineWidth,
                subdivision: .radial(subdivision),
                insideOut: true)
            outline.scale = .one
        }
        
        #if SUPPORT_DEBUG_GESTURE
        let meshPoints = Submesh.generateCylindricalSurface(
            radius: radius,
            length: length,
            subdivision: .radial(subdivision)).positions
        components.set(CollisionComponent(shapes: [.generateConvex(from: meshPoints)]))
        #endif
    }
    
    override func enableOutline(_ visible: Bool) {
        occlusion.isEnabled = visible
        wireframe.isEnabled = visible
        outline.isEnabled = visible
    }
}

fileprivate func updateModelEntities(
    _ intrinsics: CylinderEntity.Intrinsics,
    _ occlusion: ModelEntity,
    _ wireframe: ModelEntity,
    _ surface: ModelEntity,
    _ outline: ModelEntity
) {
    
    let radius = intrinsics.radius
    let length = intrinsics.length
    let outlineWidth = intrinsics.outlineWidth
    let shape = intrinsics.shape
    let subdivision = intrinsics.subdivision
    
    switch shape {
    case .volume:
        
        let submesh = Submesh.generateCylinder(radius: 1.0, length: 1.0,
                                               subdivision: subdivision)
        let mesh = MeshResource.generate(from: submesh)
        let baseScale = simd_float3(radius, length, radius)
        let weights = simd_float3(1, 2, 1)
        
        occlusion.model?.mesh = mesh
        occlusion.scale = baseScale - cylinderOcclusionDepth * weights
        
        wireframe.model?.mesh = mesh
        wireframe.scale = baseScale
        
        surface.model?.mesh = mesh
        surface.scale = baseScale
        
        outline.model?.mesh = .generate(from: submesh.inverted)
        outline.scale = baseScale + outlineWidth * weights
    
    case .surface:
        
        occlusion.model?.mesh = .generateVolumetricCylindricalSurface(
            radius: radius - cylinderOcclusionDepth - 0.00001,
            length: length,
            padding: cylinderOcclusionDepth,
            subdivision: .radial(subdivision)
        )
        occlusion.scale = .one
        
        let surfaceMesh = MeshResource.generateCylindricalSurface(
            radius: 1.0, length: 1.0, subdivision: subdivision)
        
        wireframe.model?.mesh = surfaceMesh
        wireframe.scale = .init(radius, length, radius)
        
        surface.model?.mesh = surfaceMesh
        surface.scale = wireframe.scale
        
        outline.model?.mesh = .generateVolumetricCylindricalSurface(
            radius: radius,
            length: length,
            padding: outlineWidth,
            subdivision: .radial(subdivision),
            insideOut: true)
        outline.scale = .one
    }
}
