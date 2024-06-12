//
//  ModelEntity.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import RealityKit
import ARKit

extension ModelEntity {
    
    class func generateWireframe(from meshAnchor: MeshAnchor) async -> ModelEntity? {
        guard let shape = try? await ShapeResource.generateStaticMesh(from: meshAnchor) else { return nil }
        
        let mesh = MeshResource.generate(from: meshAnchor)
        let entity = ModelEntity(mesh: mesh, materials: .mesh)
        entity.name = meshAnchor.id.uuidString
        entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
        entity.collision = CollisionComponent(shapes: [shape], isStatic: true)
        entity.components.set(InputTargetComponent())
        entity.physicsBody = PhysicsBodyComponent(mode: .static)
        return entity
    }
}
