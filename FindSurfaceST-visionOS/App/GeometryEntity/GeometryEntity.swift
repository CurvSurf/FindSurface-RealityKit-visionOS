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
            let (begin, end) = torus.calcAngleRange(from: inliers)
            if begin == .zero && end == .degrees(360) {
                return TorusEntity(meanRadius: torus.meanRadius, tubeRadius: torus.tubeRadius) as GeometryEntity
            }
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
    let angle = atan2f(a.x, a.y)
    if angle < 0 {
        return angle + .pi * 2.0
    } else {
        return angle
    }
}

fileprivate func angleBetween(_ a: simd_float2, _ b: simd_float2) -> Float {
    return angle(b) - angle(a)
}

import FindSurface_visionOS

extension Torus {
    func calcAngleRange(from inliers: [simd_float3]) -> (begin: Angle, end: Angle) {
        
        let projected = inliers.map { point in
            normalize(simd_float2(point.x, point.z))
        }
        var projectedCenter = projected.reduce(.zero, +) / Float(projected.count)
        
        if length(projectedCenter) < 0.1 {
            return (begin: .zero, end: .degrees(360))
        }
        projectedCenter = normalize(projectedCenter)
        
        let baseAngle = angleBetween(.init(1, 0), projectedCenter)
        
        let angles = projected.map {
            return angleBetween($0, projectedCenter) - baseAngle
        }
        
        guard let (beginAngle, endAngle) = angles.minAndMax() else {
            return (begin: .zero, end: .degrees(360))
        }
        
        var begin = Angle(radians: Double(beginAngle))
        var end = Angle(radians: Double(endAngle))
        
        while begin.degrees < 0 {
            begin = Angle(degrees: begin.degrees + 360)
        }
        begin = Angle(degrees: begin.degrees.truncatingRemainder(dividingBy: 360))
        
        while end.degrees < 0 {
            end = Angle(degrees: end.degrees + 360)
        }
        end = Angle(degrees: end.degrees.truncatingRemainder(dividingBy: 360))
        
        return (begin: begin, end: end)
    }
}
