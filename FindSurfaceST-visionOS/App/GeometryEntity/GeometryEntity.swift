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
            let (begin, delta) = torus.calcAngleRange(from: inliers)
            if delta >= .degrees(360) {
                return TorusEntity(meanRadius: torus.meanRadius, tubeRadius: torus.tubeRadius) as GeometryEntity
            }
            return TorusEntity(meanRadius: torus.meanRadius, tubeRadius: torus.tubeRadius, shape: .partialSurface(begin, delta))
        }()
        }
            
        entity.name = object.name
        entity.transform = Transform(matrix: object.object.extrinsics)
        entity.components.set(PersistentComponent(object: object))
        return entity
    }
}

fileprivate func angle(_ a: simd_float3, _ b: simd_float3, _ c: simd_float3 = .init(0, -1, 0)) -> Float {
    let angle = acos(dot(a, b))
    if dot(c, cross(a, b)) < 0 {
        return -angle
    } else {
        return angle
    }
}

import FindSurface_visionOS

extension Torus {
    func calcAngleRange(from inliers: [simd_float3]) -> (begin: Angle, delta: Angle) {
        
        let projected = inliers.map { point in
            normalize(simd_float3(point.x, 0, point.z))
        }
        var projectedCenter = projected.reduce(.zero, +) / Float(projected.count)
//        
//        print("""
//let projected = [
//\t\(projected.map { "simd_float2(\($0.x), \($0.y))" }.joined(separator: ",\n"))
//]
//""")
        
        if length(projectedCenter) < 0.1 {
            return (begin: .zero, delta: .degrees(360))
        }
        projectedCenter = normalize(projectedCenter)
        
        let baseAngle = angle(.init(1, 0, 0), projectedCenter)
        
        let angles = projected.map {
            return angle(projectedCenter, $0)
        }
        
        guard let (beginAngle, endAngle) = angles.minAndMax() else {
            return (begin: .zero, delta: .degrees(360))
        }
        
        let begin = Angle(radians: Double(beginAngle + baseAngle))
        let end = Angle(radians: Double(endAngle + baseAngle))
        let delta = end - begin
        
        return (begin: begin, delta: delta)
    }
}
