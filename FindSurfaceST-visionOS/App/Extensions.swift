//
//  Extensions.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import RealityKit
import ARKit

extension ModelEntity {
    
//    class func generateGeometryEntity(from object: PersistentObject) async -> ModelEntity {
//        
//        let entity: ModelEntity = switch object {
//            
//        case let .plane(_, plane, _, _): {
//            let mesh = MeshResource.generateBox(width: plane.width, height: plane.height, depth: 0.001)
//            return ModelEntity(mesh: mesh, materials: .plane)
//        }()
//        case let .sphere(_, sphere, _, _): {
//            let mesh = MeshResource.generateSphere(radius: sphere.radius)
//            return ModelEntity(mesh: mesh, materials: .sphere)
//        }()
//        case let .cylinder(_, cylinder, _, _): {
//            let mesh = MeshResource.generateCylinder(height: cylinder.height, radius: cylinder.radius)
//            return ModelEntity(mesh: mesh, materials: .cylinder)
//        }()
//        case let .cone(_, cone, _, _): {
//            let mesh = MeshResource.generateCone(topRadius: cone.topRadius, bottomRadius: cone.bottomRadius, height: cone.height)
//            return ModelEntity(mesh: mesh, materials: .cone)
//        }()
//        case let .torus(_, torus, _, _): {
//            let mesh = MeshResource.generateTorus(meanRadius: torus.meanRadius, tubeRadius: torus.tubeRadius)
//            return ModelEntity(mesh: mesh, materials: .torus)
//        }()
//        }
//            
//        entity.name = object.name
//        entity.transform = Transform(matrix: object.object.extrinsics)
//        entity.components.set(OpacityComponent(opacity: 0.2))
//        entity.components.set(PersistentComponent(object: object))
//        return entity
//    }
    
    class func generatePointcloudEntity(name: String, points: [simd_float3], transform: Transform, materials: [any Material]) async -> ModelEntity {
        
        let mesh = MeshResource.generateBox(size: 0.01)
        
        let model0 = mesh.contents.instances["MeshModel-0"]
        let modelName = model0!.model
        
        let instances: [MeshResource.Instance] = points.enumerated().map { index, point in
            let transform = Transform(translation: point)
            return MeshResource.Instance(id: "MeshModel=\(index + 1)", model: modelName, at: transform.matrix)
        }
        
        var contents = MeshResource.Contents()
        contents.models = mesh.contents.models
        contents.instances = MeshInstanceCollection(instances)
        
        do {
            let finalMesh = try await MeshResource(from: contents)
            let entity = ModelEntity(mesh: finalMesh, materials: materials)
            entity.name = name
            entity.components[OpacityComponent.self] = .init(opacity: 0.5)
            entity.transform = transform
            return entity
        } catch {
            fatalError()
        }
    }
    
    class func generatePointcloudEntity(from object: PersistentObject) async -> ModelEntity {
        let name = "\(object.name) (inliers)"
        let materials: [any Material] = switch object {
        case .plane:    .plane
        case .sphere:   .sphere
        case .cylinder: .cylinder
        case .cone:     .cone
        case .torus:    .torus
        }
        return await generatePointcloudEntity(name: name,
                                              points: object.inliers, 
                                              transform: Transform(matrix: object.object.extrinsics),
                                              materials: materials)
    }
    
    
}

extension String.StringInterpolation {
    mutating func appendInterpolation(length value: Float) {
        appendLiteral(String(format: "%.1f", value * 100))
    }
    
    mutating func appendInterpolation(position value: simd_float3) {
        appendLiteral(String(format: "(%.1f, %.1f, %.1f)", value.x * 100, value.y * 100, value.z * 100))
    }
    
    mutating func appendInterpolation(direction value: simd_float3) {
        appendLiteral(String(format: "(%.3f, %.3f, %.3f)", value.x, value.y, value.z) )
    }
}
