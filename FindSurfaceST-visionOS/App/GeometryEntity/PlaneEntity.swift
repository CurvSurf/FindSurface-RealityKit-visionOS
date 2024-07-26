//
//  PlaneEntity.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/25/24.
//

import Foundation
import RealityKit

fileprivate let planeOcclusionDepth: Float = 0.00001
fileprivate let occlusionMaterials = [OcclusionMaterial()]
fileprivate let surfaceMaterials = [UnlitMaterial(color: .red.withAlphaComponent(0.2))]
fileprivate let outlineMaterials = [UnlitMaterial(color: .black)]

@MainActor
final class PlaneEntity: GeometryEntity {
 
    enum Shape: Equatable, Hashable, CaseIterable {
        case volume
        case surface
    }
    
    struct Intrinsics: Equatable {
        var width: Float
        var height: Float
        var depth: Float
        var outlineWidth: Float
        var shape: Shape
        init(width: Float = 1, height: Float = 1, depth: Float = 0.0002,
             outlineWidth: Float = 0.005, shape: Shape = .volume) {
            self.width = width
            self.height = height
            self.depth = depth
            self.outlineWidth = outlineWidth
            self.shape = shape
        }
    }
    private(set) var intrinsics: Intrinsics
    
    private let occlusion: ModelEntity
    private let surface: ModelEntity
    private let outline: ModelEntity
    
    required init() {
    
        let intrinsics = Intrinsics()
        let dummy = MeshResource.generatePlane(width: 1, height: 1)
        let occlusion = ModelEntity(mesh: dummy, materials: occlusionMaterials)
        let surface = ModelEntity(mesh: dummy, materials: surfaceMaterials)
        let outline = ModelEntity(mesh: dummy, materials: outlineMaterials)
        updateModelEntities(intrinsics, occlusion, surface, outline)
        
        self.intrinsics = intrinsics
        self.occlusion = occlusion
        self.surface = surface
        self.outline = outline
        super.init()
        
        addChild(occlusion)
        addChild(surface)
        addChild(outline)
        
        #if SUPPORT_DEBUG_GESTURE
        components.set(CollisionComponent(shapes: [.generateBox(size: outline.scale)]))
        components.set(InputTargetComponent())
        components.set(DebugGestureComponent())
        #endif
    }
    
    convenience init(width: Float, height: Float, depth: Float = 0.0002,
                     outlineWidth: Float = 0.005, shape: Shape = .volume) {
        self.init()
        update { intrinsics in
            intrinsics.width = width
            intrinsics.height = height
            intrinsics.depth = depth
            intrinsics.outlineWidth = outlineWidth
            intrinsics.shape = shape
        }
    }
    
    @MainActor
    func update(block: (inout Intrinsics) -> Void) {
        
        var intrinsics = self.intrinsics
        block(&intrinsics)
        
        guard intrinsics != self.intrinsics else { return }
        defer { self.intrinsics = intrinsics }
        
        let w = intrinsics.width
        let h = intrinsics.height
        let d = intrinsics.depth
        let outlineWidth = intrinsics.outlineWidth
        let shape = intrinsics.shape
        
        guard shape == self.intrinsics.shape else {
            updateModelEntities(intrinsics, occlusion, surface, outline)
            return
        }
        
        occlusion.scale = simd_float3(w, h, d - planeOcclusionDepth * 2)
        surface.scale = simd_float3(w, h, d)
        outline.scale = surface.scale + .init(repeating: outlineWidth)
        
        #if SUPPORT_DEBUG_GESTURE
        components.set(CollisionComponent(shapes: [.generateBox(size: outline.scale)]))
        #endif
    }
    
    override func enableOutline(_ visible: Bool) {
        occlusion.isEnabled = visible
        outline.isEnabled = visible
    }
}

fileprivate func updateModelEntities(
    _ intrinsics: PlaneEntity.Intrinsics,
    _ occlusion: ModelEntity,
    _ surface: ModelEntity,
    _ outline: ModelEntity
) {
    
    let w = intrinsics.width
    let h = intrinsics.height
    let d = intrinsics.depth
    let outlineWidth = intrinsics.outlineWidth
    let shape = intrinsics.shape
    
    let submesh = Submesh.generateCube(width: 1, height: 1, depth: 1)
    let mesh = MeshResource.generate(from: submesh)
    
    occlusion.model?.mesh = mesh
    occlusion.scale = .init(w, h, d - planeOcclusionDepth * 2)
    
    switch shape {
    case .volume:
        
        surface.model?.mesh = mesh
        surface.scale = .init(w, h, d)
        surface.position.z = 0
    
    case .surface:
        
        surface.model?.mesh = .generatePlane(width: w, height: h)
        surface.scale = .init(w, h, d)
        surface.position.z = 0.5 * d
        
    }
    
    outline.model?.mesh = .generate(from: submesh.inverted)
    outline.scale = surface.scale + .init(repeating: outlineWidth)
}
