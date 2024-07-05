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

struct Submesh {
    var positions: [simd_float3]
    var normals: [simd_float3]
    var texcoords: [simd_float2]
    var triangleIndices: [UInt32]
}

extension MeshResource {
    static func generate(name: String = "", from submesh: Submesh) -> MeshResource {
        
        var descriptor = name.isEmpty ? MeshDescriptor() : MeshDescriptor(name: name)
        descriptor.positions = MeshBuffer(submesh.positions)
        descriptor.normals = MeshBuffer(submesh.normals)
        descriptor.textureCoordinates = MeshBuffer(submesh.texcoords)
        descriptor.primitives = .triangles(submesh.triangleIndices)
        
        return try! MeshResource.generate(from: [descriptor])
    }
}

extension Submesh {
    
    static func +(lhs: Self, rhs: Self) -> Self {
        let positions = lhs.positions + rhs.positions
        let normals = lhs.normals + rhs.normals
        let texcoords = lhs.texcoords + rhs.texcoords
        let baseVertex = UInt32(lhs.positions.count)
        let triangleIndices = lhs.triangleIndices + rhs.triangleIndices.map { $0 + baseVertex }
        return Submesh(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
}

// plane
extension Submesh {
    static func generateVolumetricPlane(width: Float, height: Float,
                                        thickness: Float = 0.001,
                                        useClockwiseTriangleWinding: Bool = false) -> Submesh {
        
        let w = width * 0.5
        let h = height * 0.5
        let d = thickness * 0.5
        
        let ulf = simd_float3(-w, +h, +d)
        let urf = simd_float3(+w, +h, +d)
        let llf = simd_float3(-w, -h, +d)
        let lrf = simd_float3(+w, -h, +d)
        let ulb = simd_float3(-w, +h, -d)
        let urb = simd_float3(+w, +h, -d)
        let llb = simd_float3(-w, -h, -d)
        let lrb = simd_float3(+w, -h, -d)
        
        let positions = [
            ulf, urf, llf, lrf, // front
            urb, ulb, lrb, llb, // back
            ulb, ulf, llb, llf, // left
            urf, urb, lrf, lrb, // right
            ulb, urb, ulf, urf, // top
            llf, lrf, llb, lrb  // bottom
        ]
        
        var normals = [simd_float3](repeating: .init(0, 0, 1), count: 4) +
        [simd_float3](repeating: .init(0, 0, -1), count: 4) +
        [simd_float3](repeating: .init(1, 0, 0), count: 4) +
        [simd_float3](repeating: .init(-1, 0, 0), count: 4) +
        [simd_float3](repeating: .init(0, 1, 0), count: 4) +
        [simd_float3](repeating: .init(0, -1, 0), count: 4)
        
        let texcoords = [
            simd_float2(0, 0), simd_float2(1, 0), simd_float2(0, 1), simd_float2(1, 1),
            simd_float2(1, 0), simd_float2(0, 0), simd_float2(1, 1), simd_float2(0, 1),
            simd_float2(0, 0), simd_float2(0, 0), simd_float2(0, 1), simd_float2(0, 1),
            simd_float2(1, 0), simd_float2(1, 0), simd_float2(1, 1), simd_float2(1, 1),
            simd_float2(0, 0), simd_float2(1, 0), simd_float2(0, 0), simd_float2(1, 0),
            simd_float2(0, 1), simd_float2(1, 1), simd_float2(0, 1), simd_float2(1, 1)
        ]
        
        let baseIndices: [UInt32] = [0, 2, 3, 0, 3, 1]
        var triangleIndices: [UInt32] = (0..<6).map { seed in
            baseIndices.map { seed * 4 + $0 }
        }.flatMap { $0 }
        
        if useClockwiseTriangleWinding {
            triangleIndices.reverse()
            normals = normals.map { $0 * -1 }
        }
        
        return .init(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
}

extension MeshResource {
    static func generateVolumetricPlane(width: Float, height: Float, thickness: Float = 0.001, useClockwiseTriangleWinding: Bool = false) -> MeshResource {
        let submesh = Submesh.generateVolumetricPlane(width: width, height: height,
                                                      thickness: thickness,
                                                      useClockwiseTriangleWinding: useClockwiseTriangleWinding)
        return .generate(from: submesh)
    }
}

// sphere
extension Submesh {
    static func generateLowPolySphere(radius: Float,
                                      subdivisions: Int = 36,
                                      useClockwiseTriangleWinding: Bool = false) -> Submesh {
        
        let thetaCount = subdivisions / 2 + 1
        let phiCount = subdivisions + 1
        let vertexCount = phiCount * thetaCount
        let faceCount = vertexCount * 2
        let indexCount = faceCount * 3
        
        var positions = [simd_float3]()
        positions.reserveCapacity(vertexCount)
        var normals = [simd_float3]()
        normals.reserveCapacity(vertexCount)
        var texcoords = [simd_float2]()
        texcoords.reserveCapacity(vertexCount)
        var triangleIndices = [UInt32]()
        triangleIndices.reserveCapacity(indexCount)
        
        let unitAngle = 2.0 * Float.pi / Float(subdivisions)
        
        for thetaIndex in 0...thetaCount {
            let theta = Float(thetaIndex) * unitAngle
            
            for phiIndex in 0...phiCount {
                let phi = Float(phiIndex) * unitAngle
                
                let nx = sin(theta) * cos(phi)
                let ny = cos(theta)
                let nz = sin(theta) * sin(phi)
                
                let normal = simd_float3(nx, ny, nz)
                let position = radius * normal
                let texcoord = simd_float2(phi / (2 * .pi), theta / .pi)
                
                positions.append(position)
                normals.append(normal)
                texcoords.append(texcoord)
            }
        }
        
        for thetaIndex in 0..<thetaCount {
            for phiIndex in 0..<(phiCount - 1) {
                let nextThetaIndex = thetaIndex + 1
                let nextPhiIndex = phiIndex + 1
                
                let v0 = UInt32((thetaIndex * (phiCount + 1)) + phiIndex)
                let v1 = UInt32((nextThetaIndex * (phiCount + 1)) + phiIndex)
                let v2 = UInt32((thetaIndex * (phiCount + 1)) + nextPhiIndex)
                let v3 = UInt32((nextThetaIndex * (phiCount + 1)) + nextPhiIndex)
                
                triangleIndices.append(contentsOf: [v0, v2, v1])
                triangleIndices.append(contentsOf: [v1, v2, v3])
            }
        }
        
        if useClockwiseTriangleWinding {
            triangleIndices.reverse()
            normals = normals.map { $0 * -1 }
        }
        
        return .init(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
}

extension MeshResource {
    static func generateLowPolySphere(radius: Float, subdivisions: Int = 36, useClockwiseTriangleWinding: Bool = false) -> MeshResource {
        let submesh = Submesh.generateLowPolySphere(radius: radius, subdivisions: subdivisions,
                                                    useClockwiseTriangleWinding: useClockwiseTriangleWinding)
        return .generate(from: submesh)
    }
}

// auxiliary
extension Submesh {
    static func generateCircle(radius: Float,
                               subdivisions: Int = 36,
                               useClockwiseTriangleWinding: Bool = false) -> Submesh {
        
        let vertexCount = subdivisions + 2 // center + duplicated ends
        let faceCount = subdivisions
        let indexCount = faceCount * 3
        
        var positions = [simd_float3]()
        positions.reserveCapacity(vertexCount)
        var normals = [simd_float3](repeating: .init(0, 1, 0), count: vertexCount)
        var texcoords = [simd_float2]()
        texcoords.reserveCapacity(vertexCount)
        var triangleIndices = [UInt32]()
        triangleIndices.reserveCapacity(indexCount)
        
        let centerPosition = simd_float3(0, 0, 0)
        let centerTexcoord = simd_float2(0.25, 0.25)
        
        positions.append(centerPosition)
        texcoords.append(centerTexcoord)
        
        for k in 0...subdivisions {
            let ratio = Float(k) / Float(subdivisions)
            let angle = 2.0 * .pi * ratio
            let sine = sin(angle)
            let cosine = cos(angle)
            
            let position = simd_float3(radius * cosine, 0, radius * sine)
            let texcoord = centerTexcoord + 0.25 * simd_float2(cosine, -sine)
            
            positions.append(position)
            texcoords.append(texcoord)
        }
        
        for i in 0..<subdivisions {
            let curr = UInt32(i + 1)
            let next = curr + 1
            triangleIndices.append(contentsOf: [
                0, next, curr
            ])
        }
        
        if useClockwiseTriangleWinding {
            triangleIndices.reverse()
            normals = normals.map { $0 * -1 }
        }
        
        return .init(positions: positions,
                     normals: normals,
                     texcoords: texcoords,
                     triangleIndices: triangleIndices)
    }
    
    static func generateHollowCircle(innerRadius: Float, outerRadius: Float,
                                     subdivisions: Int = 36,
                                     defineCircularTexcoords: Bool = false,
                                     useClockwiseTriangleWinding: Bool = false) -> Submesh {
        
        let vertexCount = (subdivisions + 1) * 2
        let faceCount = subdivisions * 2
        let indexCount = faceCount * 3
        
        var positions = [simd_float3]()
        positions.reserveCapacity(vertexCount)
        var normals = [simd_float3](repeating: .init(0, 1, 0), count: vertexCount)
        var texcoords = [simd_float2]()
        texcoords.reserveCapacity(vertexCount)
        var triangleIndices = [UInt32]()
        triangleIndices.reserveCapacity(indexCount)
        
        let radiusRatio = innerRadius / outerRadius
        
        for k in 0...subdivisions {
            let ratio = Float(k) / Float(subdivisions)
            let angle = 2.0 * .pi * ratio
            let sine = sin(angle)
            let cosine = cos(angle)
            
            var outerTexcoord = simd_float2(ratio, 0)
            var innerTexcoord = simd_float2(ratio, 1)
            
            if defineCircularTexcoords {
                outerTexcoord = simd_float2(cosine, -sine)
                innerTexcoord = radiusRatio * outerTexcoord
            }
            
            let outerPosition = outerRadius * simd_float3(cosine, 0, sine)
            let innerPosition = radiusRatio * outerPosition
            
            positions.append(outerPosition)
            positions.append(innerPosition)
            
            texcoords.append(outerTexcoord)
            texcoords.append(innerTexcoord)
        }
        
        for k in 0..<subdivisions {
            let currOuterIndex = UInt32(2 * k)
            let currInnerIndex = UInt32(2 * k + 1)
            let nextOuterIndex = UInt32(2 * k + 2)
            let nextInnerIndex = UInt32(2 * k + 3)
            
            triangleIndices.append(contentsOf: [
                nextInnerIndex, nextOuterIndex, currOuterIndex,
                nextInnerIndex, currOuterIndex, currInnerIndex
            ])
        }
        
        if useClockwiseTriangleWinding {
            triangleIndices.reverse()
            normals = normals.map { $0 * -1 }
        }
        
        return .init(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
    
}

// cone
extension Submesh {
    
    static func generateConicalSurface(topRadius: Float,
                                       bottomRadius: Float,
                                       height: Float,
                                       radialSubdivisions: Int = 36,
                                       lateralSubdivisions: Int = 2,
                                       useClockwiseTriangleWinding: Bool = false) -> Submesh {
        
        let circleCount = radialSubdivisions + 1 // duplicated end-point
        let floorCount = lateralSubdivisions + 1
        let vertexCount = circleCount * floorCount
        let faceCount = radialSubdivisions * lateralSubdivisions
        let indexCount = faceCount * 3
        
        var positions = [simd_float3]()
        positions.reserveCapacity(vertexCount)
        var normals = [simd_float3]()
        normals.reserveCapacity(vertexCount)
        var texcoords = [simd_float2]()
        texcoords.reserveCapacity(vertexCount)
        var triangleIndices = [UInt32]()
        triangleIndices.reserveCapacity(indexCount)
        
        for circleIndex in 0..<circleCount {
            let circleRatio = Float(circleIndex) / Float(radialSubdivisions)
            let angle = 2.0 * .pi * circleRatio
            let sine = sin(angle)
            let cosine = cos(angle)
            let normal = simd_float3(cosine, 0, sine)
            
            for floorIndex in 0..<floorCount {
                let floorRatio = Float(floorIndex) / Float(lateralSubdivisions)
                let radius = bottomRadius * floorRatio + topRadius * (1.0 - floorRatio)
                let height = 0.5 * height * (1.0 - 2.0 * floorRatio)
                let position = radius * normal + simd_float3(0, height, 0)
                let normal = normal
                let texcoord = simd_float2(circleRatio, floorRatio)
                
                positions.append(position)
                normals.append(normal)
                texcoords.append(texcoord)
            }
        }
        
        for r in 0..<radialSubdivisions {
            let rightBaseIndex = UInt32(r * floorCount)
            let leftBaseIndex = UInt32((r + 1) * floorCount)
            for l in 0..<lateralSubdivisions {
                let topLeftIndex = leftBaseIndex + UInt32(l)
                let topRightIndex = rightBaseIndex + UInt32(l)
                let bottomLeftIndex = leftBaseIndex + UInt32(l + 1)
                let bottomRightIndex = rightBaseIndex + UInt32(l + 1)
                
                triangleIndices.append(contentsOf: [
                    topRightIndex, topLeftIndex, bottomLeftIndex,
                    topRightIndex, bottomLeftIndex, bottomRightIndex
                ])
            }
        }
        
        if useClockwiseTriangleWinding {
            triangleIndices.reverse()
            normals = normals.map { $0 * -1 }
        }
        
        return .init(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
}

extension MeshResource {
    
    static func generateCone(topRadius: Float, bottomRadius: Float,
                             height: Float,
                             radialSubdivisions: Int = 36,
                             lateralSubdivisions: Int = 2,
                             useClockwiseTriangleWinding: Bool = false) -> MeshResource {
        let heightOffset = simd_float3(0, height * 0.5, 0)
        
        var topCover = Submesh.generateCircle(radius: topRadius,
                                              subdivisions: radialSubdivisions,
                                              useClockwiseTriangleWinding: useClockwiseTriangleWinding)
        topCover.positions = topCover.positions.map { $0 + heightOffset }
        topCover.texcoords = topCover.texcoords.map { $0 * 0.5 }
        
        var bottomCover = Submesh.generateCircle(radius: bottomRadius,
                                                 subdivisions: radialSubdivisions,
                                                 useClockwiseTriangleWinding: !useClockwiseTriangleWinding)
        bottomCover.positions = bottomCover.positions.map { $0 - heightOffset }
        bottomCover.texcoords = bottomCover.texcoords.map { $0 * 0.5 + simd_float2(0.5, 0) }
        
        var side = Submesh.generateConicalSurface(topRadius: topRadius, bottomRadius: bottomRadius,
                                                  height: height,
                                                  radialSubdivisions: radialSubdivisions,
                                                  lateralSubdivisions: lateralSubdivisions,
                                                  useClockwiseTriangleWinding: useClockwiseTriangleWinding)
        side.texcoords = side.texcoords.map { $0 * simd_float2(1.0, 0.5) + simd_float2(0, 0.5) }
        
        return .generate(from: topCover + side + bottomCover)
    }
    
    static func generateConicalSurface(topRadius: Float, bottomRadius: Float,
                                       height: Float,
                                       radialSubdivisions: Int = 36,
                                       lateralSubdivisions: Int = 2,
                                       useClockwiseTriangleWinding: Bool = false) -> MeshResource {
        let submesh = Submesh.generateConicalSurface(topRadius: topRadius, bottomRadius: bottomRadius,
                                                     height: height,
                                                     radialSubdivisions: radialSubdivisions,
                                                     lateralSubdivisions: lateralSubdivisions,
                                                     useClockwiseTriangleWinding: useClockwiseTriangleWinding)
        return .generate(from: submesh)
    }
    
    static func generateVolumetricConicalSurface(topRadius: Float, bottomRadius: Float,
                                                 height: Float,
                                                 thickness: Float = 0.001,
                                                 radialSubdivisions: Int = 36,
                                                 lateralSubdivisions: Int = 2,
                                                 defineCircularTexcoordsOnCovers: Bool = false,
                                                 useClockwiseTriangleWinding: Bool = false) -> MeshResource {
        let heightOffset = simd_float3(0, height * 0.5, 0)
        let topInnerRadius = topRadius - thickness * 0.5
        let topOuterRadius = topRadius + thickness * 0.5
        let bottomInnerRadius = bottomRadius - thickness * 0.5
        let bottomOuterRadius = bottomRadius + thickness * 0.5
        
        var topCover = Submesh.generateHollowCircle(innerRadius: topInnerRadius, outerRadius: topOuterRadius,
                                                    subdivisions: radialSubdivisions,
                                                    defineCircularTexcoords: defineCircularTexcoordsOnCovers,
                                                    useClockwiseTriangleWinding: useClockwiseTriangleWinding)
        topCover.positions = topCover.positions.map { $0 + heightOffset }
        if defineCircularTexcoordsOnCovers {
            topCover.texcoords = topCover.texcoords.map { $0 * 0.5 }
        } else {
            topCover.texcoords = topCover.texcoords.map { $0 * simd_float2(1.0, 0.25) }
        }
        
        var bottomCover = Submesh.generateHollowCircle(innerRadius: bottomInnerRadius, outerRadius: bottomOuterRadius,
                                                       subdivisions: radialSubdivisions,
                                                       defineCircularTexcoords: defineCircularTexcoordsOnCovers,
                                                       useClockwiseTriangleWinding: !useClockwiseTriangleWinding)
        bottomCover.positions = bottomCover.positions.map { $0 - heightOffset }
        if defineCircularTexcoordsOnCovers {
            bottomCover.texcoords = bottomCover.texcoords.map { $0 * 0.5 + simd_float2(0.5, 0) }
        } else {
            bottomCover.texcoords = bottomCover.texcoords.map { $0 * simd_float2(1.0, 0.25) + simd_float2(0, 0.25) }
        }
        
        var outerSide = Submesh.generateConicalSurface(topRadius: topOuterRadius, bottomRadius: bottomOuterRadius,
                                                       height: height,
                                                       radialSubdivisions: radialSubdivisions,
                                                       lateralSubdivisions: lateralSubdivisions,
                                                       useClockwiseTriangleWinding: useClockwiseTriangleWinding)
        outerSide.texcoords = outerSide.texcoords.map { $0 * simd_float2(1.0, 0.25) + simd_float2(0, 0.5) }
        
        var innerSide = Submesh.generateConicalSurface(topRadius: topInnerRadius, bottomRadius: bottomInnerRadius,
                                                       height: height,
                                                       radialSubdivisions: radialSubdivisions,
                                                       lateralSubdivisions: lateralSubdivisions,
                                                       useClockwiseTriangleWinding: !useClockwiseTriangleWinding)
        innerSide.texcoords = innerSide.texcoords.map { $0 * simd_float2(1.0, 0.25) + simd_float2(0, 0.75) }
        
        return .generate(from: topCover + outerSide + innerSide + bottomCover)
    }
}

// cylinder
extension Submesh {
    
    static func generateCylindricalSurface(radius: Float, height: Float,
                                           radialSubdivisions: Int = 36,
                                           lateralSubdivisions: Int = 3,
                                           useClockwiseTriangleWinding: Bool = false) -> Submesh {
        
        return generateConicalSurface(topRadius: radius, bottomRadius: radius,
                                      height: height,
                                      radialSubdivisions: radialSubdivisions,
                                      lateralSubdivisions: lateralSubdivisions,
                                      useClockwiseTriangleWinding: useClockwiseTriangleWinding)
    }
}

extension MeshResource {
    
    static func generateCylinder(radius: Float, height: Float,
                                 radialSubdivisions: Int = 36,
                                 lateralSubdivisions: Int = 3,
                                 useClockwiseTriangleWinding: Bool = false) -> MeshResource {
        let heightOffset = simd_float3(0, height * 0.5, 0)
        
        var topCover = Submesh.generateCircle(radius: radius,
                                              subdivisions: radialSubdivisions,
                                              useClockwiseTriangleWinding: useClockwiseTriangleWinding)
        topCover.positions = topCover.positions.map { $0 + heightOffset }
        topCover.texcoords = topCover.texcoords.map { $0 * 0.5 }
        
        var bottomCover = Submesh.generateCircle(radius: radius,
                                                 subdivisions: radialSubdivisions,
                                                 useClockwiseTriangleWinding: !useClockwiseTriangleWinding)
        bottomCover.positions = bottomCover.positions.map { $0 - heightOffset }
        bottomCover.texcoords = bottomCover.texcoords.map { $0 * 0.5 + simd_float2(0.5, 0) }
        
        var side = Submesh.generateCylindricalSurface(radius: radius, height: height,
                                                      radialSubdivisions: radialSubdivisions,
                                                      lateralSubdivisions: lateralSubdivisions,
                                                      useClockwiseTriangleWinding: useClockwiseTriangleWinding)
        side.texcoords = side.texcoords.map { $0 * simd_float2(1.0, 0.5) + simd_float2(0, 0.5) }
        
        return .generate(from: topCover + side + bottomCover)
    }
    
    static func generateCylindricalSurface(radius: Float, height: Float,
                                           radialSubdivisions: Int = 36,
                                           lateralSubdivisions: Int = 3,
                                           useClockwiseTriangleWinding: Bool = false) -> MeshResource {
        let submesh = Submesh.generateCylindricalSurface(radius: radius, height: height,
                                                         radialSubdivisions: radialSubdivisions,
                                                         lateralSubdivisions: lateralSubdivisions,
                                                         useClockwiseTriangleWinding: useClockwiseTriangleWinding)
        return .generate(from: submesh)
    }
    
    static func generateVolumetricCylindricalSurface(radius: Float, height: Float,
                                                     thickness: Float = 0.001,
                                                     radialSubdivisions: Int = 36,
                                                     lateralSubdivisions: Int = 3,
                                                     defineCircularTexcoordsOnCovers: Bool = false,
                                                     useClockwiseTriangleWinding: Bool = false) -> MeshResource {
        let heightOffset = simd_float3(0, height * 0.5, 0)
        let innerRadius = radius - thickness * 0.5
        let outerRadius = radius + thickness * 0.5
        
        var topCover = Submesh.generateHollowCircle(innerRadius: innerRadius, outerRadius: outerRadius,
                                                    subdivisions: radialSubdivisions,
                                                    defineCircularTexcoords: defineCircularTexcoordsOnCovers,
                                                    useClockwiseTriangleWinding: useClockwiseTriangleWinding)
        topCover.positions = topCover.positions.map { $0 + heightOffset }
        if defineCircularTexcoordsOnCovers {
            topCover.texcoords = topCover.texcoords.map { $0 * 0.5 }
        } else {
            topCover.texcoords = topCover.texcoords.map { $0 * simd_float2(1.0, 0.25) }
        }
        
        var bottomCover = Submesh.generateHollowCircle(innerRadius: innerRadius, outerRadius: outerRadius,
                                                       subdivisions: radialSubdivisions,
                                                       defineCircularTexcoords: defineCircularTexcoordsOnCovers,
                                                       useClockwiseTriangleWinding: !useClockwiseTriangleWinding)
        bottomCover.positions = bottomCover.positions.map { $0 - heightOffset }
        if defineCircularTexcoordsOnCovers {
            bottomCover.texcoords = bottomCover.texcoords.map { $0 * 0.5 + simd_float2(0.5, 0) }
        } else {
            bottomCover.texcoords = bottomCover.texcoords.map { $0 * simd_float2(1.0, 0.25) + simd_float2(0, 0.25) }
        }
        
        var outerSide = Submesh.generateCylindricalSurface(radius: outerRadius, height: height,
                                                           radialSubdivisions: radialSubdivisions,
                                                           lateralSubdivisions: lateralSubdivisions,
                                                           useClockwiseTriangleWinding: useClockwiseTriangleWinding)
        outerSide.texcoords = outerSide.texcoords.map { $0 * simd_float2(1.0, 0.25) + simd_float2(0, 0.5) }
        
        var innerSide = Submesh.generateCylindricalSurface(radius: innerRadius, height: height,
                                                           radialSubdivisions: radialSubdivisions,
                                                           lateralSubdivisions: lateralSubdivisions,
                                                           useClockwiseTriangleWinding: !useClockwiseTriangleWinding)
        innerSide.texcoords = innerSide.texcoords.map { $0 * simd_float2(1.0, 0.25) + simd_float2(0, 0.75) }
        
        return .generate(from: topCover + outerSide + innerSide + bottomCover)
    }
}

// torus
extension Submesh {
    static func generateTorus(meanRadius: Float,
                              tubeRadius: Float,
                              toroidalSubdivisions: Int = 36,
                              poloidalSubdivisions: Int = 36,
                              useClockwiseTriangleWinding: Bool = false) -> Submesh {
        
        let vertexCount = (poloidalSubdivisions + 1) * (toroidalSubdivisions + 1)
        let faceCount = (poloidalSubdivisions * toroidalSubdivisions) * 2
        let indexCount = faceCount * 3
        
        var positions = [simd_float3]()
        positions.reserveCapacity(vertexCount)
        var normals = [simd_float3]()
        normals.reserveCapacity(vertexCount)
        var texcoords = [simd_float2]()
        texcoords.reserveCapacity(vertexCount)
        var triangleIndices = [UInt32]()
        triangleIndices.reserveCapacity(indexCount)
        
        let toroidals = (0...toroidalSubdivisions).map {
            let angle = 2.0 * .pi * Float($0) / Float(toroidalSubdivisions)
            let sine = sin(angle)
            let cosine = cos(angle)
            return (sine, cosine)
        }.enumerated().map { $0 }
        
        let poloidals = (0...poloidalSubdivisions).map {
            let angle = 2.0 * .pi * Float($0) / Float(poloidalSubdivisions)
            let sine = sin(angle)
            let cosine = cos(angle)
            return (sine, cosine)
        }.enumerated().map { $0 }
        
        for (toroidal, poloidal) in product(toroidals, poloidals) {
            let (tIndex, (sinT, cosT)) = toroidal
            let (pIndex, (sinP, cosP)) = poloidal
            
            let tubeCenter = simd_float3(meanRadius * cosT, 0, meanRadius * sinT)
            let normal = simd_float3(cosP * cosT, sinP, cosP * sinT)
            let position = tubeCenter + tubeRadius * normal
            let u = Float(tIndex) / Float(toroidalSubdivisions)
            let v = Float(pIndex) / Float(poloidalSubdivisions)
            let texcoord = simd_float2(u, v)
            
            positions.append(position)
            normals.append(normal)
            texcoords.append(texcoord)
        }
        
        let stride = poloidalSubdivisions + 1
        for t in 0..<toroidalSubdivisions {
            for p in 0..<poloidalSubdivisions {
                let a = UInt32(t * stride + p)
                let b = a + 1
                let c = UInt32((t + 1) * stride + p)
                let d = c + 1
                
                triangleIndices.append(contentsOf: [a, b, d, a, d, c])
            }
        }
        
        if useClockwiseTriangleWinding {
            triangleIndices.reverse()
        }
        
        return .init(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
    
    static func generateToricSurface(meanRadius: Float, tubeRadius: Float,
                                     beginAngle: Angle = .degrees(0),
                                     endAngle: Angle = .degrees(360),
                                     toroidalSubdivisions: Int = 36,
                                     poloidalSubdivisions: Int = 36,
                                     useClockwiseTriangleWinding: Bool = false) -> Submesh {
        
        var _beginAngle = beginAngle.degrees
        while _beginAngle < 0 {
            _beginAngle += 360
        }
        let beginAngle = Angle(degrees: _beginAngle.truncatingRemainder(dividingBy: 360))
        
        var _endAngle = endAngle.degrees
        while _endAngle < 0 {
            _endAngle += 360
        }
        let endAngle = Angle(degrees: _endAngle.truncatingRemainder(dividingBy: 360))
        
        var _angle = endAngle.degrees - beginAngle.degrees
        if _angle < 0 {
            _angle += 360
        }
        let angle = Angle(degrees: _angle)
        
        let ratio = Float(angle.degrees) / 360
        let sectionalToroidalSubdivisions: Int = max(Int(Float(toroidalSubdivisions) * ratio), 1)
        let vertexCount = (poloidalSubdivisions + 1) * (sectionalToroidalSubdivisions + 1)
        let faceCount = (poloidalSubdivisions * sectionalToroidalSubdivisions) * 2
        let indexCount = faceCount * 3
        
        var positions = [simd_float3]()
        positions.reserveCapacity(vertexCount)
        var normals = [simd_float3]()
        normals.reserveCapacity(vertexCount)
        var texcoords = [simd_float2]()
        texcoords.reserveCapacity(vertexCount)
        var triangleIndices = [UInt32]()
        triangleIndices.reserveCapacity(indexCount)
        
        let toroidals = (0...sectionalToroidalSubdivisions).map {
            let angle = Float(angle.radians) * Float($0) / Float(sectionalToroidalSubdivisions)
            let sine = sin(angle)
            let cosine = cos(angle)
            return (sine, cosine)
        }.enumerated().map { $0 }
        
        let poloidals = (0...poloidalSubdivisions).map {
            let angle = 2.0 * .pi * Float($0) / Float(poloidalSubdivisions)
            let sine = sin(angle)
            let cosine = cos(angle)
            return (sine, cosine)
        }.enumerated().map { $0 }
        
        for (toroidal, poloidal) in product(toroidals, poloidals) {
            let (tIndex, (sinT, cosT)) = toroidal
            let (pIndex, (sinP, cosP)) = poloidal
            
            let tubeCenter = simd_float3(meanRadius * cosT, 0, meanRadius * sinT)
            let normal = simd_float3(cosP * cosT, sinP, cosP * sinT)
            let position = tubeCenter + tubeRadius * normal
            let u = Float(tIndex) / Float(sectionalToroidalSubdivisions)
            let v = Float(pIndex) / Float(poloidalSubdivisions)
            let texcoord = simd_float2(u, v)
            
            positions.append(position)
            normals.append(normal)
            texcoords.append(texcoord)
        }
        
        let stride = poloidalSubdivisions + 1
        for t in 0..<sectionalToroidalSubdivisions {
            for p in 0..<poloidalSubdivisions {
                let a = UInt32(t * stride + p)
                let b = a + 1
                let c = UInt32((t + 1) * stride + p)
                let d = c + 1
                
                triangleIndices.append(contentsOf: [a, b, d, a, d, c])
            }
        }
        
        if useClockwiseTriangleWinding {
            triangleIndices.reverse()
        }
        
        return .init(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
}

extension MeshResource {
    
    static func generateTorus(meanRadius: Float, tubeRadius: Float,
                              beginAngle: Angle = .degrees(0),
                              endAngle: Angle = .degrees(360),
                              toroidalSubdivisions: Int = 36,
                              poloidalSubdivisions: Int = 36,
                              useClockwiseTriangleWinding: Bool = false) -> MeshResource {
        if beginAngle == .degrees(0) && endAngle == .degrees(360) {
            let submesh = Submesh.generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                                toroidalSubdivisions: toroidalSubdivisions,
                                                poloidalSubdivisions: poloidalSubdivisions,
                                                useClockwiseTriangleWinding: useClockwiseTriangleWinding)
            return .generate(from: submesh)
        } else {
            let beginCircleDirection = simd_float3(cos(Float(beginAngle.radians)), 0, sin(Float(beginAngle.radians)))
            let beginCirclePosition = meanRadius * beginCircleDirection
            let beginCircleNormal = normalize(cross(.init(0, 1, 0), beginCircleDirection))
            
            let beginRotation = simd_quatf(from: .init(0, 1, 0), to: beginCircleNormal)
            var beginCircle = Submesh.generateCircle(radius: tubeRadius, subdivisions: poloidalSubdivisions, useClockwiseTriangleWinding: useClockwiseTriangleWinding)
            if beginRotation.angle != 0 {
                beginCircle.positions = beginCircle.positions.map { beginRotation.act($0) + beginCirclePosition }
                beginCircle.normals = beginCircle.normals.map { beginRotation.act($0) }
            } else {
                beginCircle.positions = beginCircle.positions.map { $0 + beginCirclePosition }
            }
            beginCircle.texcoords = beginCircle.texcoords.map { $0 * 0.5 }
            
            let endCircleDirection = simd_float3(cos(Float(endAngle.radians)), 0, sin(Float(endAngle.radians)))
            let endCirclePosition = meanRadius * endCircleDirection
            let endCircleNormal = normalize(cross(endCircleDirection, .init(0, 1, 0)))
            
            let endRotation = simd_quatf(from: .init(0, 1, 0), to: endCircleNormal)
            var endCircle = Submesh.generateCircle(radius: tubeRadius, subdivisions: poloidalSubdivisions, useClockwiseTriangleWinding: useClockwiseTriangleWinding)
            if endRotation.angle != 0 {
                endCircle.positions = endCircle.positions.map { endRotation.act($0) + endCirclePosition }
                endCircle.normals = endCircle.normals.map { endRotation.act($0) }
            } else {
                endCircle.positions = endCircle.positions.map { $0 + endCirclePosition }
            }
            endCircle.texcoords = endCircle.texcoords.map { $0 * 0.5 + simd_float2(0.5, 0) }
            
            var surface = Submesh.generateToricSurface(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                                       beginAngle: beginAngle, endAngle: endAngle,
                                                       toroidalSubdivisions: toroidalSubdivisions,
                                                       poloidalSubdivisions: poloidalSubdivisions,
                                                       useClockwiseTriangleWinding: useClockwiseTriangleWinding)
            let surfaceRotation = simd_quatf(from: .init(1, 0, 0), to: beginCircleDirection)
            if surfaceRotation.angle != 0 {
                surface.positions = surface.positions.map { surfaceRotation.act($0) }
                surface.normals = surface.normals.map { surfaceRotation.act($0) }
            }
            surface.texcoords = surface.texcoords.map { $0 * simd_float2(1, 0.5) + simd_float2(0, 0.5) }
            
            return .generate(from: beginCircle + surface + endCircle)
        }
    }

    static func generateToricSurface(meanRadius: Float, tubeRadius: Float,
                                     beginAngle: Angle = .degrees(0),
                                     endAngle: Angle = .degrees(360),
                                     toroidalSubdivisions: Int = 36,
                                     poloidalSubdivisions: Int = 36,
                                     useClockwiseTriangleWinding: Bool = false) -> MeshResource {
        if beginAngle == .degrees(0) && endAngle == .degrees(360) {
            let submesh = Submesh.generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                                toroidalSubdivisions: toroidalSubdivisions,
                                                poloidalSubdivisions: poloidalSubdivisions,
                                                useClockwiseTriangleWinding: useClockwiseTriangleWinding)
            return .generate(from: submesh)
        } else {
            let beginCircleDirection = simd_float3(cos(Float(beginAngle.radians)), 0, sin(Float(beginAngle.radians)))
            
            let rotation = simd_quatf(from: .init(1, 0, 0), to: beginCircleDirection)
            var submesh = Submesh.generateToricSurface(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                                       beginAngle: beginAngle, endAngle: endAngle,
                                                       toroidalSubdivisions: toroidalSubdivisions,
                                                       poloidalSubdivisions: poloidalSubdivisions,
                                                       useClockwiseTriangleWinding: useClockwiseTriangleWinding)
            let surfaceRotation = simd_quatf(from: .init(1, 0, 0), to: beginCircleDirection)
            if rotation.angle != 0 {
                submesh.positions = submesh.positions.map { surfaceRotation.act($0) }
                submesh.normals = submesh.normals.map { surfaceRotation.act($0) }
            }
            return .generate(from: submesh)
        }
    }
    
    static func generateVolumetricToricSurface(meanRadius: Float, tubeRadius: Float,
                                               beginAngle: Angle = .degrees(0),
                                               endAngle: Angle = .degrees(360),
                                               thickness: Float = 0.001,
                                               toroidalSubdivisions: Int = 36,
                                               poloidalSubdivisions: Int = 36,
                                               defineCircularTexcoordsOnCovers: Bool = false,
                                               useClockwiseTriangleWinding: Bool = false) -> MeshResource {
        if beginAngle == .degrees(0) && endAngle == .degrees(360) {
            let submesh = Submesh.generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                                toroidalSubdivisions: toroidalSubdivisions,
                                                poloidalSubdivisions: poloidalSubdivisions,
                                                useClockwiseTriangleWinding: useClockwiseTriangleWinding)
            return .generate(from: submesh)
        } else {
            let innerTubeRadius = tubeRadius - thickness * 0.5
            let outerTubeRadius = tubeRadius + thickness * 0.5
            
            let beginCircleDirection = simd_float3(cos(Float(beginAngle.radians)), 0, sin(Float(beginAngle.radians)))
            let beginCirclePosition = meanRadius * beginCircleDirection
            let beginCircleNormal = normalize(cross(.init(0, 1, 0), beginCircleDirection))
            
            let beginRotation = simd_quatf(from: .init(0, 1, 0), to: beginCircleNormal)
            var beginCircle = Submesh.generateHollowCircle(innerRadius: innerTubeRadius, outerRadius: outerTubeRadius, subdivisions: poloidalSubdivisions, defineCircularTexcoords: defineCircularTexcoordsOnCovers)
            if beginRotation.angle != 0 {
                beginCircle.positions = beginCircle.positions.map { beginRotation.act($0) + beginCirclePosition }
                beginCircle.normals = beginCircle.normals.map { beginRotation.act($0) }
            } else {
                beginCircle.positions = beginCircle.positions.map { $0 + beginCirclePosition }
            }
            beginCircle.texcoords = beginCircle.texcoords.map { $0 * 0.5 }
            
            let endCircleDirection = simd_float3(cos(Float(endAngle.radians)), 0, sin(Float(endAngle.radians)))
            let endCirclePosition = meanRadius * endCircleDirection
            let endCircleNormal = normalize(cross(endCircleDirection, .init(0, 1, 0)))
            
            let endRotation = simd_quatf(from: .init(0, 1, 0), to: endCircleNormal)
            var endCircle = Submesh.generateHollowCircle(innerRadius: innerTubeRadius, outerRadius: outerTubeRadius, subdivisions: poloidalSubdivisions, defineCircularTexcoords: defineCircularTexcoordsOnCovers)
            if endRotation.angle != 0 {
                endCircle.positions = endCircle.positions.map { endRotation.act($0) + endCirclePosition }
                endCircle.normals = endCircle.normals.map { endRotation.act($0) }
            } else {
                endCircle.positions = endCircle.positions.map { $0 + endCirclePosition }
            }
            endCircle.texcoords = endCircle.texcoords.map { $0 * 0.5 + simd_float2(0.5, 0) }
            
            let surfaceRotation = simd_quatf(from: .init(1, 0, 0), to: beginCircleDirection)
            
            var outerSurface = Submesh.generateToricSurface(meanRadius: meanRadius, tubeRadius: outerTubeRadius,
                                                            beginAngle: beginAngle, endAngle: endAngle,
                                                            toroidalSubdivisions: toroidalSubdivisions,
                                                            poloidalSubdivisions: poloidalSubdivisions,
                                                            useClockwiseTriangleWinding: useClockwiseTriangleWinding)
            if surfaceRotation.angle != 0 {
                outerSurface.positions = outerSurface.positions.map { surfaceRotation.act($0) }
                outerSurface.normals = outerSurface.normals.map { surfaceRotation.act($0) }
            }
            outerSurface.texcoords = outerSurface.texcoords.map { $0 * simd_float2(1, 0.5) + simd_float2(0, 0.5) }
            
            var innerSurface = Submesh.generateToricSurface(meanRadius: meanRadius, tubeRadius: innerTubeRadius,
                                                            beginAngle: beginAngle, endAngle: endAngle,
                                                            toroidalSubdivisions: toroidalSubdivisions,
                                                            poloidalSubdivisions: poloidalSubdivisions,
                                                            useClockwiseTriangleWinding: !useClockwiseTriangleWinding)
            if surfaceRotation.angle != 0 {
                innerSurface.positions = innerSurface.positions.map { surfaceRotation.act($0) }
                innerSurface.normals = innerSurface.normals.map { surfaceRotation.act($0) }
            }
            innerSurface.texcoords = innerSurface.texcoords.map { $0 * simd_float2(1, 0.5) + simd_float2(0, 0.5) }
            
            return .generate(from: beginCircle + outerSurface + innerSurface + endCircle)
        }
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
    
//    class func generateVolumePlane(width: Float, height: Float, 
//                                   thickness: Float = 0.001,
//                                   useClockwiseTriangleWinding: Bool = false) -> MeshResource {
//        
//        let w = width * 0.5
//        let h = height * 0.5
//        let d = thickness * 0.5
//        
//        let faceTexcoords = [
//            simd_float2(0, 0),
//            simd_float2(1, 0),
//            simd_float2(0, 1),
//            simd_float2(1, 1)
//        ]
//        
//        let ulf = simd_float3(-w, +h, +d)
//        let urf = simd_float3(+w, +h, +d)
//        let llf = simd_float3(-w, -h, +d)
//        let lrf = simd_float3(+w, -h, +d)
//        let ulb = simd_float3(-w, +h, -d)
//        let urb = simd_float3(+w, +h, -d)
//        let llb = simd_float3(-w, -h, -d)
//        let lrb = simd_float3(+w, -h, -d)
//        
//        let positions = [
//            ulf, urf, llf, lrf, // front
//            urb, ulb, lrb, llb, // back
//            ulb, ulf, llb, llf, // left
//            urf, urb, lrf, lrb, // right
//            ulb, urb, ulf, urf, // top
//            llf, lrf, llb, lrb  // bottom
//        ]
//        
//        let normals = [simd_float3](repeating: .init(0, 0, 1), count: 4) +
//        [simd_float3](repeating: .init(0, 0, -1), count: 4) +
//        [simd_float3](repeating: .init(1, 0, 0), count: 4) +
//        [simd_float3](repeating: .init(-1, 0, 0), count: 4) +
//        [simd_float3](repeating: .init(0, 1, 0), count: 4) +
//        [simd_float3](repeating: .init(0, -1, 0), count: 4)
//        
//        let texcoords = [
//            simd_float2(0, 0), simd_float2(1, 0), simd_float2(0, 1), simd_float2(1, 1),
//            simd_float2(1, 0), simd_float2(0, 0), simd_float2(1, 1), simd_float2(0, 1),
//            simd_float2(0, 0), simd_float2(0, 0), simd_float2(0, 1), simd_float2(0, 1),
//            simd_float2(1, 0), simd_float2(1, 0), simd_float2(1, 1), simd_float2(1, 1),
//            simd_float2(0, 0), simd_float2(1, 0), simd_float2(0, 0), simd_float2(1, 0),
//            simd_float2(0, 1), simd_float2(1, 1), simd_float2(0, 1), simd_float2(1, 1)
//        ]
//        
//        let baseIndices: [UInt32] = [0, 2, 3, 0, 3, 1]
//        var triangleIndices: [UInt32] = (0..<6).map { seed in
//            baseIndices.map { seed * 4 + $0 }
//        }.flatMap { $0 }
//        
//        if useClockwiseTriangleWinding {
//            triangleIndices.reverse()
//        }
//        
//        var descriptor = MeshDescriptor(name: "Plane")
//        descriptor.positions = MeshBuffer(positions)
//        descriptor.primitives = .triangles(triangleIndices)
//        descriptor.textureCoordinates = MeshBuffer(texcoords)
//        descriptor.normals = MeshBuffer(normals)
//        
//        return try! MeshResource.generate(from: [descriptor])
//    }
//    
//    class func generateLowPolySphere(radius: Float, 
//                                     subdivisions: Int = 36,
//                                     useClockwiseTriangleWinding: Bool = false) -> MeshResource {
//        
//        let thetaCount = subdivisions / 2 + 1
//        let phiCount = subdivisions + 1
//        let vertexCount = phiCount * thetaCount
//        let faceCount = vertexCount * 2
//        let indexCount = faceCount * 3
//        
//        var positions = [simd_float3]()
//        positions.reserveCapacity(vertexCount)
//        var normals = [simd_float3]()
//        normals.reserveCapacity(vertexCount)
//        var texcoords = [simd_float2]()
//        texcoords.reserveCapacity(vertexCount)
//        var triangleIndices = [UInt32]()
//        triangleIndices.reserveCapacity(indexCount)
//        
//        let unitAngle = 2.0 * Float.pi / Float(subdivisions)
//        
//        for thetaIndex in 0...thetaCount {
//            let theta = Float(thetaIndex) * unitAngle
//            
//            for phiIndex in 0...phiCount {
//                let phi = Float(phiIndex) * unitAngle
//                
//                let nx = sin(theta) * cos(phi)
//                let ny = cos(theta)
//                let nz = sin(theta) * sin(phi)
//                
//                let normal = simd_float3(nx, ny, nz)
//                let position = radius * normal
//                let texcoord = simd_float2(phi / (2 * .pi), theta / .pi)
//                
//                positions.append(position)
//                normals.append(normal)
//                texcoords.append(texcoord)
//            }
//        }
//        
//        for thetaIndex in 0..<thetaCount {
//            for phiIndex in 0..<(phiCount - 1) {
//                let nextThetaIndex = thetaIndex + 1
//                let nextPhiIndex = phiIndex + 1
//                
//                let v0 = UInt32((thetaIndex * (phiCount + 1)) + phiIndex)
//                let v1 = UInt32((nextThetaIndex * (phiCount + 1)) + phiIndex)
//                let v2 = UInt32((thetaIndex * (phiCount + 1)) + nextPhiIndex)
//                let v3 = UInt32((nextThetaIndex * (phiCount + 1)) + nextPhiIndex)
//                
//                triangleIndices.append(contentsOf: [v0, v2, v1])
//                triangleIndices.append(contentsOf: [v1, v2, v3])
//            }
//        }
//        
//        if useClockwiseTriangleWinding {
//            triangleIndices.reverse()
//        }
//        
//        var descriptor = MeshDescriptor(name: "LowPolySphere")
//        descriptor.positions = MeshBuffer(positions)
//        descriptor.primitives = .triangles(triangleIndices)
//        descriptor.textureCoordinates = MeshBuffer(texcoords)
//        descriptor.normals = MeshBuffer(normals)
//        
//        return try! MeshResource.generate(from: [descriptor])
//    }
//    
//    class func generateCylinder(radius: Float,
//                                height: Float,
//                                radialSubdivisions: Int = 36,
//                                lateralSubdivisions: Int = 3,
//                                useClockwiseTriangleWinding: Bool = false) -> MeshResource {
//        return generateCone(topRadius: radius, bottomRadius: radius,
//                            height: height,
//                            radialSubdivisions: radialSubdivisions,
//                            lateralSubdivisions: lateralSubdivisions,
//                            useClockwiseTriangleWinding: useClockwiseTriangleWinding)
//    }
//    
//    class func generateCone(topRadius: Float,
//                            bottomRadius: Float,
//                            height: Float,
//                            radialSubdivisions: Int = 36,
//                            lateralSubdivisions: Int = 2,
//                            useClockwiseTriangleWinding: Bool = false) -> MeshResource {
//        
//        let circleCount = radialSubdivisions + 1 // duplicated end-point
//        let floorCount = lateralSubdivisions + 1
//        let vertexCount = circleCount * floorCount
//        let faceCount = radialSubdivisions * lateralSubdivisions
//        let indexCount = faceCount * 3
//        
//        var positions = [simd_float3]()
//        positions.reserveCapacity(vertexCount)
//        var normals = [simd_float3]()
//        normals.reserveCapacity(vertexCount)
//        var texcoords = [simd_float2]()
//        texcoords.reserveCapacity(vertexCount)
//        var triangleIndices = [UInt32]()
//        triangleIndices.reserveCapacity(indexCount)
//        
//        for circleIndex in 0..<circleCount {
//            let circleRatio = Float(circleIndex) / Float(radialSubdivisions)
//            let angle = 2.0 * .pi * circleRatio
//            let sine = sin(angle)
//            let cosine = cos(angle)
//            let normal = simd_float3(cosine, 0, sine)
//            
//            for floorIndex in 0..<floorCount {
//                let floorRatio = Float(floorIndex) / Float(lateralSubdivisions)
//                let radius = bottomRadius * floorRatio + topRadius * (1.0 - floorRatio)
//                let height = 0.5 * height * (1.0 - 2.0 * floorRatio)
//                let position = radius * normal + simd_float3(0, height, 0)
//                let normal = normal
//                let texcoord = simd_float2(circleRatio, floorRatio)
//                
//                positions.append(position)
//                normals.append(normal)
//                texcoords.append(texcoord)
//            }
//        }
//        
//        for r in 0..<radialSubdivisions {
//            let rightBaseIndex = UInt32(r * floorCount)
//            let leftBaseIndex = UInt32((r + 1) * floorCount)
//            for l in 0..<lateralSubdivisions {
//                let topLeftIndex = leftBaseIndex + UInt32(l)
//                let topRightIndex = rightBaseIndex + UInt32(l)
//                let bottomLeftIndex = leftBaseIndex + UInt32(l + 1)
//                let bottomRightIndex = rightBaseIndex + UInt32(l + 1)
//                
//                triangleIndices.append(contentsOf: [
//                    topRightIndex, topLeftIndex, bottomLeftIndex,
//                    topRightIndex, bottomLeftIndex, bottomRightIndex
//                ])
//            }
//        }
//        
//        if useClockwiseTriangleWinding {
//            triangleIndices.reverse()
//        }
//        
//        var descriptor = MeshDescriptor(name: "cone")
//        descriptor.positions = MeshBuffer(positions)
//        descriptor.primitives = .triangles(triangleIndices)
//        descriptor.textureCoordinates = MeshBuffer(texcoords)
//        descriptor.normals = MeshBuffer(normals)
//        
//        return try! MeshResource.generate(from: [descriptor])
//    }
//    
//    class func generateTorus(meanRadius: Float,
//                             tubeRadius: Float,
//                             toroidalSubdivisions: Int = 36,
//                             poloidalSubdivisions: Int = 36,
//                             useClockwiseTriangleWinding: Bool = false) -> MeshResource {
//        
//        let vertexCount = (poloidalSubdivisions + 1) * (toroidalSubdivisions + 1)
//        let faceCount = (poloidalSubdivisions * toroidalSubdivisions) * 2
//        let indexCount = faceCount * 3
//        
//        var positions = [simd_float3]()
//        positions.reserveCapacity(vertexCount)
//        var normals = [simd_float3]()
//        normals.reserveCapacity(vertexCount)
//        var textureCoordinates = [simd_float2]()
//        textureCoordinates.reserveCapacity(vertexCount)
//        var triangleIndices = [UInt32]()
//        triangleIndices.reserveCapacity(indexCount)
//        
//        let toroidals = (0...toroidalSubdivisions).map {
//            let angle = 2.0 * .pi * Float($0) / Float(toroidalSubdivisions)
//            let sine = sin(angle)
//            let cosine = cos(angle)
//            return (sine, cosine)
//        }.enumerated().map { $0 }
//        
//        let poloidals = (0...poloidalSubdivisions).map {
//            let angle = 2.0 * .pi * Float($0) / Float(poloidalSubdivisions)
//            let sine = sin(angle)
//            let cosine = cos(angle)
//            return (sine, cosine)
//        }.enumerated().map { $0 }
//        
//        for (toroidal, poloidal) in product(toroidals, poloidals) {
//            let (tIndex, (sinT, cosT)) = toroidal
//            let (pIndex, (sinP, cosP)) = poloidal
//            
//            let tubeCenter = simd_float3(meanRadius * cosT, 0, meanRadius * sinT)
//            let normal = simd_float3(cosP * cosT, sinP, cosP * sinT)
//            let position = tubeCenter + tubeRadius * normal
//            let u = Float(tIndex) / Float(toroidalSubdivisions)
//            let v = Float(pIndex) / Float(poloidalSubdivisions)
//            let textureCoordinate = simd_float2(u, v)
//            
//            positions.append(position)
//            normals.append(normal)
//            textureCoordinates.append(textureCoordinate)
//        }
//        
//        let stride = poloidalSubdivisions + 1
//        for t in 0..<toroidalSubdivisions {
//            for p in 0..<poloidalSubdivisions {
//                let a = UInt32(t * stride + p)
//                let b = a + 1
//                let c = UInt32((t + 1) * stride + p)
//                let d = c + 1
//                
//                triangleIndices.append(contentsOf: [a, b, d, a, d, c])
//            }
//        }
//        
//        if useClockwiseTriangleWinding {
//            triangleIndices.reverse()
//        }
//        
//        var descriptor = MeshDescriptor(name: "torus")
//        descriptor.positions = MeshBuffer(positions)
//        descriptor.primitives = .triangles(triangleIndices)
//        descriptor.textureCoordinates = MeshBuffer(textureCoordinates)
//        descriptor.normals = MeshBuffer(normals)
//        
//        return try! MeshResource.generate(from: [descriptor])
//    }
    
}
