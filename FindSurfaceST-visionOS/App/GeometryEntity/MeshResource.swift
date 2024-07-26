//
//  MeshResource.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import RealityKit
import simd
import Algorithms
import ARKit
import SwiftUI

import Foundation
import RealityKit
import SwiftUI

extension MeshResource {
    
    static func generate(name: String = "", from submesh: Submesh) -> MeshResource {
        
        var descriptor = name.isEmpty ? MeshDescriptor() : MeshDescriptor(name: name)
        descriptor.positions = MeshBuffer(submesh.positions)
        if !submesh.normals.allSatisfy({ normal in
            normal == .zero
        }) {
            descriptor.normals = MeshBuffer(submesh.normals)
        }
        if !submesh.texcoords.allSatisfy({ texcoord in
            texcoord == .zero
        }) {
            descriptor.textureCoordinates = MeshBuffer(submesh.texcoords)
        }
        descriptor.primitives = .triangles(submesh.triangleIndices)
        
        do {
            return try MeshResource.generate(from: [descriptor])
        } catch {
            fatalError("\(error.localizedDescription)")
        }
    }
}

// Plane
extension MeshResource {
    static func generateCube(name: String = "",
                             width: Float, height: Float, depth: Float,
                             insideOut: Bool = false) -> MeshResource {
        
        let submesh = Submesh.generateCube(width: width, height: height, depth: depth)
        
        return .generate(name: name, from: insideOut ? submesh.inverted : submesh)
    }
}

// Sphere
extension MeshResource {
    
    static func generateSphere(name: String = "",
                               radius: Float,
                               subdivision: SphereSubdivision = .sphericalCoordinates,
                               insideOut: Bool = false) -> MeshResource {
        let submesh = Submesh.generateSphere(radius: radius, subdivision: subdivision)
        return .generate(name: name, from: insideOut ? submesh.inverted : submesh)
    }
}

// Cylinder
extension MeshResource {
    
    static func generateCylinder(name: String = "",
                                 radius: Float,
                                 length: Float,
                                 subdivision: CylinderSubdivision = .both(36, 3),
                                 insideOut: Bool = false) -> MeshResource {
        
        let submesh = Submesh.generateCylinder(radius: radius,
                                               length: length,
                                               subdivision: subdivision)
        return .generate(name: name, from: insideOut ? submesh.inverted : submesh)
    }
    
    static func generateCylindricalSurface(name: String = "",
                                           radius: Float,
                                           length: Float,
                                           subdivision: CylinderSubdivision = .both(36, 3),
                                           insideOut: Bool = false) -> MeshResource {
        
        let submesh = Submesh.generateCylindricalSurface(radius: radius,
                                                         length: length,
                                                         subdivision: subdivision)
        return .generate(name: name, from: insideOut ? submesh.inverted : submesh)
    }
    
    static func generateVolumetricCylindricalSurface(
        name: String = "",
        radius: Float,
        length: Float,
        padding: Float,
        subdivision: CylinderSubdivision = .both(36, 3),
        insideOut: Bool = false
    ) -> MeshResource {
        
        let submesh = Submesh.generateVolumetricCylindricalSurface(
            radius: radius,
            length: length,
            padding: padding,
            subdivision: subdivision)
        return .generate(name: name, from: insideOut ? submesh.inverted : submesh)
    }
}

// Cone
extension MeshResource {
    
    static func generateCone(name: String = "",
                             topRadius: Float,
                             bottomRadius: Float,
                             length: Float,
                             padding: Float = 0.0,
                             subdivision: ConeSubdivision = .both(36, 2),
                             insideOut: Bool = false) -> MeshResource {
    
        let submesh = Submesh.generateCone(topRadius: topRadius,
                                           bottomRadius: bottomRadius,
                                           length: length,
                                           padding: padding,
                                           subdivision: subdivision)
        return .generate(name: name, from: insideOut ? submesh.inverted : submesh)
    }
    
    static func generateConicalSurface(name: String = "",
                                       topRadius: Float,
                                       bottomRadius: Float,
                                       length: Float,
                                       subdivision: ConeSubdivision = .both(36, 2),
                                       insideOut: Bool = false) -> MeshResource {
        let submesh = Submesh.generateConicalSurface(topRadius: topRadius,
                                                     bottomRadius: bottomRadius,
                                                     length: length,
                                                     subdivision: subdivision)
        return .generate(name: name, from: insideOut ? submesh.inverted : submesh)
    }
    
    static func generateVolumetricConicalSurface(name: String = "",
                                                 topRadius: Float,
                                                 bottomRadius: Float,
                                                 length: Float,
                                                 padding: Float,
                                                 subdivision: ConeSubdivision = .both(36, 2),
                                                 insideOut: Bool = false) -> MeshResource {
        let submesh = Submesh.generateVolumetricConicalSurface(topRadius: topRadius,
                                                               bottomRadius: bottomRadius,
                                                               length: length,
                                                               padding: padding,
                                                               subdivision: subdivision)
        return .generate(name: name, from: insideOut ? submesh.inverted : submesh)
    }
}

// Torus
extension MeshResource {
    
    static func generateTorus(name: String = "",
                              meanRadius: Float,
                              tubeRadius: Float,
                              tubeBegin: Angle = .zero,
                              tubeAngle: Angle = .degrees(360),
                              padding: Float = 0.0,
                              subdivision: TorusSubdivision = .both(36, 36),
                              insideOut: Bool = false) -> MeshResource {
        
        let submesh = Submesh.generateTorus(meanRadius: meanRadius,
                                            tubeRadius: tubeRadius,
                                            tubeBegin: tubeBegin,
                                            tubeAngle: tubeAngle,
                                            padding: padding,
                                            subdivision: subdivision)
        return .generate(name: name, from: insideOut ? submesh.inverted : submesh)
    }
    
    static func generateToricSurface(name: String = "",
                                     meanRadius: Float,
                                     tubeRadius: Float,
                                     tubeBegin: Angle = .zero,
                                     tubeAngle: Angle = .degrees(360),
                                     subdivision: TorusSubdivision = .both(36, 36),
                                     insideOut: Bool = false) -> MeshResource {
        
        let submesh = Submesh.generateToricSurface(meanRadius: meanRadius,
                                                   tubeRadius: tubeRadius,
                                                   tubeBegin: tubeBegin,
                                                   tubeAngle: tubeAngle,
                                                   subdivision: subdivision)
        return .generate(name: name, from: insideOut ? submesh.inverted : submesh)
    }
    
    static func generateVolumetricToricSurface(name: String = "",
                                               meanRadius: Float,
                                               tubeRadius: Float,
                                               tubeBegin: Angle = .zero,
                                               tubeAngle: Angle = .degrees(360),
                                               padding: Float,
                                               subdivision: TorusSubdivision = .both(36, 36),
                                               insideOut: Bool = false) -> MeshResource {
        
        let submesh = Submesh.generateVolumetricToricSurface(meanRadius: meanRadius,
                                                             tubeRadius: tubeRadius,
                                                             tubeBegin: tubeBegin,
                                                             tubeAngle: tubeAngle,
                                                             padding: padding,
                                                             subdivision: subdivision)
        return .generate(name: name, from: insideOut ? submesh.inverted : submesh)
    }
}

extension MeshResource {
    
    class func generate(from meshAnchor: MeshAnchor) -> MeshResource {
        
        let geometry = meshAnchor.geometry
        var descriptor = MeshDescriptor(name: meshAnchor.id.uuidString)
        let positions = geometry.vertices.asSimdFloat3()
        let normals = geometry.normals.asSimdFloat3()
        descriptor.positions = .init(positions)
        descriptor.normals = .init(normals)
        
        let faceBuffer = geometry.faces.buffer
        let faceCount = geometry.faces.count
        let bytesPerIndex = geometry.faces.bytesPerIndex
        let indices = (0..<faceCount * 3).map { index in
            faceBuffer.contents()
                .advanced(by: index * bytesPerIndex)
                .assumingMemoryBound(to: UInt32.self)
                .pointee
        }
        descriptor.primitives = .triangles(indices)
        
        do {
            return try .generate(from: [descriptor])
        } catch {
            fatalError("\(error)")
        }
    }
}
