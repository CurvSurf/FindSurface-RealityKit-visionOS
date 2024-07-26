//
//  SphereEntity.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/25/24.
//

import Foundation
import RealityKit

fileprivate let sphereOcclusionDepth: Float = 0.0001

@MainActor
final class SphereEntity: GeometryEntity {
    
    struct Intrinsics: Equatable, Hashable {
        
        var radius: Float
        var outlineWidth: Float
        var subdivision: SphereSubdivision
        init(radius: Float = 1,
             outlineWidth: Float = 0.005,
             subdivision: SphereSubdivision = .sphericalCoordinates) {
            self.radius = radius
            self.outlineWidth = outlineWidth
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
        let radius = intrinsics.radius
        let subdivision = intrinsics.subdivision
        let outlineWidth = intrinsics.outlineWidth
        
        let submesh = Submesh.generateSphere(radius: 1.0, subdivision: subdivision)
        let mesh = MeshResource.generate(from: submesh)
        
        let occlusion = {
            let material = OcclusionMaterial()
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        occlusion.scale = .init(repeating: radius - sphereOcclusionDepth * 2)
        
        let wireframe = {
            var material = UnlitMaterial(color: .black)
            material.triangleFillMode = .lines
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        wireframe.scale = .init(repeating: radius)
        
        let surface = {
            let material = UnlitMaterial(color: .green.withAlphaComponent(0.2))
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        surface.scale = wireframe.scale
        
        let outline = {
            let mesh = MeshResource.generate(from: submesh.inverted)
            let material = UnlitMaterial(color: .black)
            let model = ModelEntity(mesh: mesh, materials: [material])
            return model
        }()
        outline.scale = surface.scale + .init(repeating: outlineWidth)
        
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
        components.set(CollisionComponent(shapes: [.generateSphere(radius: 1.0)]))
        components.set(InputTargetComponent())
        components.set(DebugGestureComponent())
        #endif
    }
    
    convenience init(radius: Float,
                     outlineWidth: Float = 0.005,
                     subdivision: SphereSubdivision = .sphericalCoordinates) {
        self.init()
        update { intrinsics in
            intrinsics.radius = radius
            intrinsics.outlineWidth = outlineWidth
            intrinsics.subdivision = subdivision
        }
    }
    
    @MainActor
    func update(block: (inout Intrinsics) -> Void) {
        
        var intrinsics = self.intrinsics
        block(&intrinsics)
        
        guard intrinsics != self.intrinsics else { return }
        
        let radius = intrinsics.radius
        let outlineWidth = intrinsics.outlineWidth
        let subdivision = intrinsics.subdivision
        
        occlusion.scale = .init(repeating: radius - sphereOcclusionDepth * 2)
        wireframe.scale = .init(repeating: radius)
        surface.scale = wireframe.scale
        outline.scale = surface.scale + .init(repeating: outlineWidth)
        
        if subdivision != self.intrinsics.subdivision {
            let submesh = Submesh.generateSphere(radius: 1, subdivision: subdivision)
            let mesh = MeshResource.generate(from: submesh)
            occlusion.model?.mesh = mesh
            wireframe.model?.mesh = mesh
            surface.model?.mesh = mesh
            outline.model?.mesh = .generate(from: submesh.inverted)
        }
        
        #if SUPPORT_DEBUG_GESTURE
        components.set(CollisionComponent(shapes: [.generateSphere(radius: radius)]))
        #endif
        
        self.intrinsics = intrinsics
    }
    
    override func enableOutline(_ visible: Bool) {
        occlusion.isEnabled = visible
        wireframe.isEnabled = visible
        outline.isEnabled = visible
    }
}
