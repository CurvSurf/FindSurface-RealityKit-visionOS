//
//  ConeEntity.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/25/24.
//

import Foundation
import RealityKit

fileprivate let coneOcclusionDepth: Float = 0.0001
fileprivate let occlusionMaterials = [OcclusionMaterial()]
fileprivate let wireframeMaterials = {
    var material = UnlitMaterial(color: .black)
    material.triangleFillMode = .lines
    return [material]
}()
fileprivate let surfaceMaterials = [UnlitMaterial(color: .cyan.withAlphaComponent(0.2))]
fileprivate let outlineMaterials = [UnlitMaterial(color: .black)]

@MainActor
final class ConeEntity: GeometryEntity {
    
    enum Shape: Equatable {
        case volume
        case surface
    }
    
    struct Intrinsics: Equatable {
        var topRadius: Float
        var bottomRadius: Float
        var length: Float
        var outlineWidth: Float
        var shape: Shape
        var subdivision: ConeSubdivision
        init(topRadius: Float = 0,
             bottomRadius: Float = 1,
             length: Float = 1,
             outlineWidth: Float = 0.005,
             shape: Shape = .volume,
             subdivision: ConeSubdivision = .both(36, 2)) {
            self.topRadius = topRadius
            self.bottomRadius = bottomRadius
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
        let meshPoints = Submesh.generateConicalSurface(topRadius: intrinsics.topRadius,
                                                        bottomRadius: intrinsics.bottomRadius,
                                                        length: intrinsics.length,
                                                        subdivision: .radial(intrinsics.subdivision)).positions
        components.set(CollisionComponent(shapes: [.generateConvex(from: meshPoints)]))
        components.set(InputTargetComponent())
        components.set(DebugGestureComponent())
        #endif
    }
    
    convenience init(topRadius: Float,
                     bottomRadius: Float,
                     length: Float,
                     outlineWidth: Float = 0.005,
                     shape: Shape = .volume,
                     subdivision: ConeSubdivision = .both(36, 2)) {
        self.init()
        update { intrinsics in
            intrinsics.topRadius = topRadius
            intrinsics.bottomRadius = bottomRadius
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
        
        updateModelEntities(intrinsics, occlusion, wireframe, surface, outline)
        
        #if SUPPORT_DEBUG_GESTURE
        let meshPoints = Submesh.generateConicalSurface(topRadius: intrinsics.topRadius,
                                                        bottomRadius: intrinsics.bottomRadius,
                                                        length: intrinsics.length,
                                                        subdivision: .radial(intrinsics.subdivision)).positions
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
    _ intrinsics: ConeEntity.Intrinsics,
    _ occlusion: ModelEntity,
    _ wireframe: ModelEntity,
    _ surface: ModelEntity,
    _ outline: ModelEntity
) {
    
    let topRadius = intrinsics.topRadius
    let bottomRadius = intrinsics.bottomRadius
    let length = intrinsics.length
    let outlineWidth = intrinsics.outlineWidth
    let shape = intrinsics.shape
    let subdivision = intrinsics.subdivision
    
    switch shape {
    case .volume:
        
        occlusion.model?.mesh = .generateCone(topRadius: topRadius,
                                              bottomRadius: bottomRadius,
                                              length: length,
                                              padding: -coneOcclusionDepth,
                                              subdivision: .radial(subdivision))
        
        let surfaceMesh = MeshResource.generateCone(topRadius: topRadius,
                                                    bottomRadius: bottomRadius,
                                                    length: length,
                                                    subdivision: subdivision)
        wireframe.model?.mesh = surfaceMesh
        surface.model?.mesh = surfaceMesh
        
        outline.model?.mesh = MeshResource.generateCone(topRadius: topRadius,
                                                        bottomRadius: bottomRadius,
                                                        length: length,
                                                        padding: outlineWidth,
                                                        subdivision: .radial(subdivision),
                                                        insideOut: true)
        
    case .surface:
        
        occlusion.model?.mesh = .generateVolumetricConicalSurface(topRadius: topRadius,
                                                                  bottomRadius: bottomRadius,
                                                                  length: length,
                                                                  padding: -coneOcclusionDepth,
                                                                  subdivision: .radial(subdivision))
        
        let surfaceMesh = MeshResource.generateConicalSurface(topRadius: topRadius,
                                                              bottomRadius: bottomRadius,
                                                              length: length,
                                                              subdivision: subdivision)
        wireframe.model?.mesh = surfaceMesh
        surface.model?.mesh = surfaceMesh
        
        outline.model?.mesh = .generateVolumetricConicalSurface(topRadius: topRadius,
                                                                bottomRadius: bottomRadius,
                                                                length: length,
                                                                padding: outlineWidth,
                                                                subdivision: .radial(subdivision),
                                                                insideOut: true)
    }
}
