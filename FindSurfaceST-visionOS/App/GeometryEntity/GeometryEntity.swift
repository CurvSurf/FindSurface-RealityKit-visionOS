//
//  Entity.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/25/24.
//

import Foundation
import RealityKit
import SwiftUI

@MainActor
class GeometryEntity: Entity {
    
    required init() {
        super.init()
    }
    
    func enableOutline(_ visible: Bool) {
        
    }
}

extension GeometryEntity {
    
    class func generateGeometryEntity(from object: PersistentObject) async -> GeometryEntity {
        
        let entity: GeometryEntity = switch object {
            
        case let .plane(_, plane, _, _): {
            return PlaneEntity(width: plane.width, height: plane.height) as GeometryEntity
        }()
        case let .sphere(_, sphere, _, _): {
            return SphereEntity(radius: sphere.radius) as GeometryEntity
        }()
        case let .cylinder(_, cylinder, _, _): {
            return CylinderEntity(radius: cylinder.radius, height: cylinder.height, shape: .surface) as GeometryEntity
        }()
        case let .cone(_, cone, _, _): {
            return ConeEntity(topRadius: cone.topRadius, bottomRadius: cone.bottomRadius, height: cone.height, shape: .surface) as GeometryEntity
        }()
        case let .torus(_, torus, inliers, _): {
            let projected = inliers.map { point in
                normalize(simd_float2(point.x, point.z))
            }
            var projectedCenter = projected.reduce(.zero, +) / Float(projected.count)
            
            if length(projectedCenter) < 0.1 {
                return TorusEntity(meanRadius: torus.meanRadius, tubeRadius: torus.tubeRadius) as GeometryEntity
            }
            projectedCenter = normalize(projectedCenter)
            
            let baseAngle = angleBetween(.init(1, 0), projectedCenter)
            
            let angles = projected.map {
                return angleBetween($0, projectedCenter) - baseAngle
            }
            
            guard let (beginAngle, endAngle) = angles.minAndMax() else {
                return TorusEntity(meanRadius: torus.meanRadius, tubeRadius: torus.tubeRadius) as GeometryEntity
            }
            
            let begin = Angle(radians: Double(beginAngle))
            let end = Angle(radians: Double(endAngle))
            
            return TorusEntity(meanRadius: torus.meanRadius, tubeRadius: torus.tubeRadius, shape: .partialSurface(begin, end))
        }()
        }
            
        entity.name = object.name
        entity.transform = Transform(matrix: object.object.extrinsics)
        entity.components.set(PersistentComponent(object: object))
        return entity
    }
}

fileprivate func angle(_ a: simd_float2) -> Float {
    return atan2f(a.x, a.y)
}

fileprivate func angleBetween(_ a: simd_float2, _ b: simd_float2) -> Float {
    return angle(b) - angle(a)
}
