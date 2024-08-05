//
//  Submesh.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 7/18/24.
//

import Foundation
import simd

enum Winding {
    case counterClockwise
    case clockwise
    
    var reversed: Winding {
        switch self {
        case .counterClockwise: return .clockwise
        case .clockwise: return .counterClockwise
        }
    }
}

struct Submesh {
    
    var positions: [simd_float3]
    var normals: [simd_float3]
    var texcoords: [simd_float2]
    var triangleIndices: [UInt32]
    let winding: Winding
    
    init(positions: [simd_float3], normals: [simd_float3] = [], texcoords: [simd_float2] = [], triangleIndices: [UInt32], winding: Winding = .counterClockwise) {
        self.positions = positions
        self.normals = normals.isEmpty ? .init(repeating: .zero, count: positions.count) : normals
        self.texcoords = texcoords.isEmpty ? .init(repeating: .zero, count: positions.count) : texcoords
        self.triangleIndices = triangleIndices
        self.winding = winding
    }
    
    /// Creates a concatenated submesh by combining the given two submeshes.
    static func +(lhs: Self, rhs: Self) -> Self {
        let positions = lhs.positions + rhs.positions
        let normals = lhs.normals + rhs.normals
        let texcoords = lhs.texcoords + rhs.texcoords
        let baseVertex = UInt32(lhs.positions.count)
        let triangleIndices = lhs.triangleIndices + rhs.triangleIndices.map { $0 + baseVertex }
        return Submesh(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
    
    /// Creates an inside out version of this submesh. This reverses triangle winding and inverts normal.
    var inverted: Submesh {
        let invertedNormals = normals.map { $0 * -1 }
        let reversedTriangleIndices = triangleIndices.chunks(ofCount: 3).map { chunk in
            let i0 = chunk[chunk.startIndex]
            let i1 = chunk[chunk.startIndex + 1]
            let i2 = chunk[chunk.startIndex + 2]
            return [i0, i2, i1]
        }.flatMap { $0 }
        return Submesh(positions: positions, normals: invertedNormals, texcoords: texcoords, triangleIndices: reversedTriangleIndices)
    }
    
    /// Create a copy of this submesh of which triangle winding is reversed.
    var reversed: Submesh {
        let reversedTriangleIndices = triangleIndices.chunks(ofCount: 3).map { chunk in
            let i0 = chunk[chunk.startIndex]
            let i1 = chunk[chunk.startIndex + 1]
            let i2 = chunk[chunk.startIndex + 2]
            return [i0, i2, i1]
        }.flatMap { $0 }
        return Submesh(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: reversedTriangleIndices, winding: winding.reversed)
    }
}

extension Submesh {
    
    mutating func translate(_ offset: simd_float3) {
        positions.translate(offset)
    }
    
    func translated(_ offset: simd_float3) -> Submesh {
        var this = self
        this.translate(offset)
        return this
    }
    
    mutating func translate(x: Float, y: Float = 0, z: Float = 0) {
        translate(simd_float3(x, y, z))
    }
    
    func translated(x: Float, y: Float = 0, z: Float = 0) -> Submesh {
        var this = self
        this.translate(x: x, y: y, z: z)
        return this
    }
    
    mutating func translate(y: Float, z: Float = 0) {
        translate(x: 0, y: y, z: z)
    }
    
    func translated(y: Float, z: Float = 0) -> Submesh {
        var this = self
        this.translate(y: y, z: z)
        return this
    }
    
    mutating func translate(z: Float) {
        translate(y: 0, z: z)
    }
    
    func translated(z: Float) -> Submesh {
        var this = self
        this.translate(z: z)
        return this
    }
    
    mutating func scale(_ factors: simd_float3) {
        positions.scale(factors)
    }
    
    func scaled(_ factors: simd_float3) -> Submesh {
        var this = self
        this.scale(factors)
        return this
    }
    
    mutating func scale(x: Float, y: Float = 0, z: Float = 0) {
        scale(simd_float3(x, y, z))
    }
    
    func scaled(x: Float, y: Float = 0, z: Float = 0) -> Submesh {
        var this = self
        this.scale(x: x, y: y, z: z)
        return this
    }
    
    mutating func scale(y: Float, z: Float = 0) {
        scale(x: 0, y: y, z: z)
    }
    
    func scaled(y: Float, z: Float = 0) -> Submesh {
        var this = self
        this.scale(y: y, z: z)
        return this
    }
    
    mutating func scale(z: Float) {
        scale(y: 0, z: z)
    }
    
    func scaled(z: Float) -> Submesh {
        var this = self
        this.scale(z: z)
        return this
    }
    
    mutating func scale(_ factor: Float) {
        scale(simd_float3(repeating: factor))
    }
    
    func scaled(_ factor: Float) -> Submesh {
        var this = self
        this.scale(factor)
        return this
    }
    
    mutating func rotate(_ rotation: simd_quatf) {
        positions.rotate(rotation)
        normals.rotate(rotation)
    }
    
    func rotated(_ rotation: simd_quatf) -> Submesh {
        var this = self
        this.rotate(rotation)
        return this
    }
    
    mutating func rotate(angle: Float, axis: simd_float3) {
        rotate(.init(angle: angle, axis: axis))
    }
               
    func rotated(angle: Float, axis: simd_float3) -> Submesh {
        var this = self
        this.rotate(angle: angle, axis: axis)
        return this
    }
    
    mutating func transform(_ transform: simd_float4x4) {
        positions = positions.map { simd_make_float3(transform * simd_float4($0, 1)) }
        normals = normals.map { simd_make_float3(transform * simd_float4($0, 0)) }
    }
    
    func transformed(_ transform: simd_float4x4) -> Submesh {
        var this = self
        this.transform(transform)
        return this
    }
}

// Plane
extension Submesh {
    
    /// Generates a submesh for a cube with the give `width`, `height` and `depth`.
    static func generateCube(width: Float, height: Float, depth: Float) -> Submesh {
        
        #if SUPPORT_DEBUG_GESTURE && !DEBUG
        guard width >= 0 && height >= 0 && depth >= 0 else {
            print("\(#function) returns a temporary submesh.")
            return generateCube(width: 1, height: 1, depth: 1)
        }
        #else
        precondition(width >= 0)
        precondition(height >= 0)
        precondition(depth >= 0)
        #endif
        
        let w = width * 0.5
        let h = height * 0.5
        let d = depth * 0.5
        
        // Cube vertices
        //
        //   2 - 6       2 - 6
        //  /|  /|       | \ |
        // 3 + 7 |   2 - 3 - 7 - 6 - 2
        // | 0 + 4   | \ | \ | \ | \ |
        // |/  |/    0 - 1 - 5 - 4 - 0
        // 1 - 5         | \ |
        //               0 - 4
        
        let p0 = simd_float3(-w, -h, -d)
        let p1 = simd_float3(-w, -h, +d)
        let p2 = simd_float3(-w, +h, -d)
        let p3 = simd_float3(-w, +h, +d)
        let p4 = simd_float3(+w, -h, -d)
        let p5 = simd_float3(+w, -h, +d)
        let p6 = simd_float3(+w, +h, -d)
        let p7 = simd_float3(+w, +h, +d)
        
        let positions = [
            p3, p1, p5, p7, // front side
            p6, p4, p0, p2, //  back side
            p2, p3, p7, p6, //    up side
            p1, p0, p4, p5, //  down side
            p7, p5, p4, p6, // right side
            p2, p0, p1, p3  //  left side
        ]
        
        let normals = [
            Array(repeating: simd_float3(0, 0, +1), count: 4),
            Array(repeating: simd_float3(0, 0, -1), count: 4),
            Array(repeating: simd_float3(0, +1, 0), count: 4),
            Array(repeating: simd_float3(0, -1, 0), count: 4),
            Array(repeating: simd_float3(+1, 0, 0), count: 4),
            Array(repeating: simd_float3(-1, 0, 0), count: 4),
        ].flatMap { $0 }
        
        // texture coordinate mapping
        //
        //       0  1/3 2/3  1
        //       |   |   |   |  f - front side
        //   0 - 0 - 1 - 2 - 3  b -  back side
        //       | f | u | r |  u -    up side
        // 1/2 - 4 - 5 - 6 - 7  d -  down side
        //       | b | d | l |  r - right side
        //   1 - 8 - 9 -10 -11  l -  left side
        
        let x0: Float = 0.0
        let x1: Float = 1.0 / 3.0
        let x2: Float = 2.0 / 3.0
        let x3: Float = 1.0
        let y0: Float = 0.0
        let y1: Float = 0.5
        let y2: Float = 1.0
        
        let texcoords: [simd_float2] = [
            .init(x0, y0), .init(x0, y1), .init(x1, y1), .init(x1, y0), // front side
            .init(x0, y1), .init(x0, y2), .init(x1, y2), .init(x1, y1), //  back side
            .init(x1, y0), .init(x1, y1), .init(x2, y1), .init(x2, y0), //    up side
            .init(x1, y1), .init(x1, y2), .init(x2, y2), .init(x2, y1), //  down side
            .init(x2, y0), .init(x2, y1), .init(x3, y1), .init(x3, y0), // right side
            .init(x2, y1), .init(x2, y2), .init(x3, y2), .init(x3, y1)  //  left side
        ]
        
        // Cube indices
        //
        //        8 -11
        //        | u |
        //        9 -10
        // 19 -22 0 - 3 15 -18 4 - 7
        //  | l | | f |  | r | | b |
        // 20 -21 1 - 2 16 -17 5 - 6
        //       11 -14
        //        | d |
        //       12 -13
        
        let indexPattern: [UInt32] = [0, 1, 2, 0, 2, 3]
        let triangleIndices = (0..<6).map { index in
            let offset = UInt32(index * 4)
            return indexPattern.map { $0 + offset }
        }.flatMap { $0 }
        
        return .init(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
}

enum SphereSubdivision: Equatable, Hashable {
    
    struct Spherical: Equatable, Hashable {
        let polar: Int
        let azimuthal: Int
        
        private init(polar: Int = 18, azimuthal: Int = 36) {
            self.polar = polar
            self.azimuthal = azimuthal
        }
        
        static var defaults = Spherical()
        static func polar(_ count: Int) -> Spherical { .init(polar: count) }
        static func azimuthal(_ count: Int) -> Spherical { .init(azimuthal: count) }
        static func both(_ pcount: Int, _ acount: Int) -> Spherical { .init(polar: pcount, azimuthal: acount) }
    }
    
    case sphericalCoordinatesWith(Spherical)
    case sphericalCoordinates
    case recursiveSubdivisionLevel(Int)
    case recursiveSubdivision
}

// Sphere
extension Submesh {
    
    static func generateSphere(
        radius: Float,
        subdivision: SphereSubdivision = .sphericalCoordinates
    ) -> Submesh {
        switch subdivision {
        case let .sphericalCoordinatesWith(details):
            return generateSphereFromSphericalCoordinates(radius: radius,
                                                          subdivision: details)
        case .sphericalCoordinates:
            return generateSphereFromSphericalCoordinates(radius: radius)
        case let .recursiveSubdivisionLevel(level):
            return generateSphereFromOctahedronExpansion(radius: radius,
                                                         subdivisionLevel: level)
        case .recursiveSubdivision:
            return generateSphereFromOctahedronExpansion(radius: radius)
        }
    }
    
    private static func generateSphereFromSphericalCoordinates(
        radius: Float,
        subdivision: SphereSubdivision.Spherical = .defaults
    ) -> Submesh {
        
        let pcount = subdivision.polar
        let acount = subdivision.azimuthal
        #if SUPPORT_DEBUG_GESTURE && !DEBUG
        guard radius >= 0 && pcount >= 3 && acount >= 3 else {
            print("\(#function) returns a temporary submesh.")
            return generateSphereFromSphericalCoordinates(radius: 1)
        }
        #else
        precondition(radius >= 0)
        precondition(pcount >= 3)
        precondition(acount >= 3)
        #endif
        
        let thetaCount = pcount + 1
        let phiCount = acount + 1
        let vertexCount = phiCount * thetaCount
        let faceCount = vertexCount * 2
        let indexCount = faceCount
        
        var positions = [simd_float3]()
        positions.reserveCapacity(vertexCount)
        var normals = [simd_float3]()
        normals.reserveCapacity(vertexCount)
        var texcoords = [simd_float2]()
        texcoords.reserveCapacity(vertexCount)
        var triangleIndices = [UInt32]()
        triangleIndices.reserveCapacity(indexCount)
        
        for thetaIndex in 0...thetaCount {
            let thetaRatio = Float(thetaIndex) / Float(thetaCount)
            let theta = thetaRatio * .pi
            let sinTheta = sin(theta)
            let cosTheta = cos(theta)
            
            for phiIndex in 0...phiCount {
                let phiRatio = Float(phiIndex) / Float(phiCount)
                let phi = phiRatio * 2.0 * .pi
                
                let nx = sinTheta * cos(phi)
                let ny = cosTheta
                let nz = sinTheta * sin(phi)
                
                let normal = simd_float3(nx, ny, nz)
                let position = radius * normal
                let texcoord = simd_float2(1.0 - phiRatio, thetaRatio)
                
                positions.append(position)
                normals.append(normal)
                texcoords.append(texcoord)
            }
        }
        
        for thetaIndex in 0..<thetaCount {
            for phiIndex in 0..<phiCount {
                let nextThetaIndex = thetaIndex + 1
                let nextPhiIndex = phiIndex + 1
                
                let thetaBase = thetaIndex * (phiCount + 1)
                let nextThetaBase = nextThetaIndex * (phiCount + 1)
                
                let i0 = UInt32(thetaBase + nextPhiIndex)
                let i1 = UInt32(nextThetaBase + nextPhiIndex)
                let i2 = UInt32(nextThetaBase + phiIndex)
                let i3 = UInt32(thetaBase + phiIndex)
                
                let indices = [i0, i1, i2, i0, i2, i3]
                triangleIndices.append(contentsOf: indices)
            }
        }
        
        return .init(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
    
    static func generateSphereFromOctahedronExpansion(
        radius: Float,
        subdivisionLevel level: Int = 4
    ) -> Submesh {
        
        #if SUPPORT_DEBUG_GESTURE && !DEBUG
        guard radius >= 0 && level >= 0 else {
            print("\(#function) returns a temporary submesh.")
            return generateSphereFromOctahedronExpansion(radius: 1)
        }
        #else
        precondition(radius >= 0)
        precondition(level >= 0)
        #endif
        
        var positions = [simd_float3]()
        var _triangleIndices = [Int]()
        
        // Octahedron triangles
        //
        //   2   2   2   2
        //  / \ / \ / \ / \
        // 0 - 5 - 1 - 4 - 0
        //  \ / \ / \ / \ /
        //   3   3   3   3
        
        
        positions.append(contentsOf: [
            simd_float3(1, 0, 0), simd_float3(-1, 0, 0),
            simd_float3(0, 1, 0), simd_float3(0, -1, 0),
            simd_float3(0, 0, 1), simd_float3(0, 0, -1)
        ])
        
        subdivide(2, 0, 5, level, &positions, &_triangleIndices)
        subdivide(0, 3, 5, level, &positions, &_triangleIndices)
        subdivide(2, 5, 1, level, &positions, &_triangleIndices)
        subdivide(5, 3, 1, level, &positions, &_triangleIndices)
        subdivide(2, 1, 4, level, &positions, &_triangleIndices)
        subdivide(1, 3, 4, level, &positions, &_triangleIndices)
        subdivide(2, 4, 0, level, &positions, &_triangleIndices)
        subdivide(4, 3, 0, level, &positions, &_triangleIndices)
        
        let normals = positions
        positions = positions.map { $0 * radius }
        
        let triangleIndices = _triangleIndices.map { UInt32($0) }
        
        return .init(positions: positions, normals: normals, triangleIndices: triangleIndices)
    }
    
    fileprivate static func subdivide(_ i0: Int, _ i1: Int, _ i2: Int, _ level: Int,
                                      _ positions: inout [simd_float3],
                                      _ triangleIndices: inout [Int]) {
        
        guard level > 1 else {
            triangleIndices.append(contentsOf: [i0, i1, i2])
            return
        }
        
        let p0 = positions[i0]
        let p1 = positions[i1]
        let p2 = positions[i2]
        
        let p01 = normalize((p0 + p1) * 0.5)
        let p12 = normalize((p1 + p2) * 0.5)
        let p20 = normalize((p2 + p0) * 0.5)
        
        positions.append(contentsOf: [p01, p12, p20])
        
        let i01 = positions.count - 3
        let i12 = i01 + 1
        let i20 = i12 + 1
        
        let nextLevel = level - 1
        subdivide(i0 , i01, i20, nextLevel, &positions, &triangleIndices)
        subdivide(i01, i1 , i12, nextLevel, &positions, &triangleIndices)
        subdivide(i01, i12, i20, nextLevel, &positions, &triangleIndices)
        subdivide(i20, i12, i2 , nextLevel, &positions, &triangleIndices)
    }
}

enum CylinderSubdivision: Equatable {
    
    case both(Int, Int)
    case radial(Int)
    case lateral(Int)
    case none
    
    static func radial(_ subdivision: Self) -> Self {
        return .radial(subdivision.radial)
    }
    static func lateral(_ subdivision: Self) -> Self {
        return .lateral(subdivision.lateral)
    }
    
    var radial: Int {
        switch self {
        case let .both(radial, _):  return radial
        case let .radial(radial):   return radial
        default:                    return 3
        }
    }
    
    var lateral: Int {
        switch self {
        case let .both(_, lateral): return lateral
        case let .lateral(lateral): return lateral
        default:                    return 1
        }
    }
}

// Cylinder
extension Submesh {
    
    static func generateCylindricalSurface(radius: Float,
                                           length: Float,
                                           subdivision: CylinderSubdivision = .both(36, 3)) -> Submesh {
        
        let rcount = subdivision.radial
        let lcount = subdivision.lateral
        
        #if SUPPORT_DEBUG_GESTURE && !DEBUG
        guard radius >= 0 && length >= 0 && lcount >= 1 && rcount >= 3 else {
            print("\(#function) returns a temporary submesh.")
            return generateCylindricalSurface(radius: 1, length: 1, subdivision: .none)
        }
        #else
        precondition(radius >= 0)
        precondition(length >= 0)
        precondition(lcount >= 1)
        precondition(rcount >= 3)
        #endif
        
        let vertexCount = (rcount + 1) * (lcount + 1)
        let faceCount = rcount * lcount
        let indexCount = faceCount * 3
        
        var positions = [simd_float3]()
        positions.reserveCapacity(vertexCount)
        var normals = [simd_float3]()
        normals.reserveCapacity(vertexCount)
        var texcoords = [simd_float2]()
        texcoords.reserveCapacity(vertexCount)
        var triangleIndices = [UInt32]()
        triangleIndices.reserveCapacity(indexCount)
        
        for radialIndex in 0...rcount {
            let radialRatio = Float(radialIndex) / Float(rcount)
            let angle = 2.0 * .pi * radialRatio
            let normal = simd_float3(angle: angle, axis: .y)
            
            for lateralIndex in 0...lcount {
                let lateralRatio = Float(lateralIndex) / Float(lcount)
                let height = 0.5 * length * mix(1, -1, t: lateralRatio)
                let position = radius * normal + simd_float3(0, height, 0)
                let texcoord = simd_float2(1.0 - radialRatio, lateralRatio)
                
                positions.append(position)
                normals.append(normal)
                texcoords.append(texcoord)
            }
        }
        
        for radialIndex in 0..<rcount {
            let rightBaseIndex = UInt32(radialIndex * (lcount + 1))
            let leftBaseIndex = UInt32((radialIndex + 1) * (lcount + 1))
            for lateralIndex in 0..<lcount {
                let topLeftIndex = leftBaseIndex + UInt32(lateralIndex)
                let topRightIndex = rightBaseIndex + UInt32(lateralIndex)
                let bottomLeftIndex = leftBaseIndex + UInt32(lateralIndex + 1)
                let bottomRightIndex = rightBaseIndex + UInt32(lateralIndex + 1)
                
                triangleIndices.append(contentsOf: [
                    topLeftIndex, bottomLeftIndex, bottomRightIndex,
                    topLeftIndex, bottomRightIndex, topRightIndex
                ])
            }
        }
        
        return .init(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
    
    private static func generateCircleCover(radius: Float, axis: simd_float3.Axis = .y, subdivision: CylinderSubdivision) -> Submesh {
        
        let rcount = subdivision.radial
        
        #if SUPPORT_DEBUG_GESTURE && !DEBUG
        guard radius >= 0 && rcount >= 3 else {
            print("\(#function) returns a temporary submesh.")
            return generateCircleCover(radius: 1, subdivision: .none)
        }
        #else
        precondition(radius >= 0)
        precondition(rcount >= 3)
        #endif
        
        let vertexCount = (rcount + 1) + 1
        let faceCount = rcount
        let indexCount = faceCount * 3
        
        var positions = [simd_float3]()
        positions.reserveCapacity(vertexCount)
        positions.append(.zero)
        let normal = switch axis {
        case .x: simd_float3(1, 0, 0)
        case .y: simd_float3(0, 1, 0)
        case .z: simd_float3(0, 0, 1)
        }
        let normals = [simd_float3](repeating: normal, count: vertexCount)
        var texcoords = [simd_float2]()
        texcoords.reserveCapacity(vertexCount)
        texcoords.append(.init(0.5, 0.5))
        var triangleIndices = [UInt32]()
        triangleIndices.reserveCapacity(indexCount)
        
        for index in 0...rcount {
            let ratio = Float(index) / Float(rcount)
            let angle = 2.0 * .pi * ratio
            
            let position = radius * simd_float3(angle: angle, axis: axis)
            let texcoord = simd_float2(angle: angle, radius: 1) * 0.5 + 0.5
            
            positions.append(position)
            texcoords.append(texcoord)
        }
        
        for index in 1...rcount {
            let i1 = UInt32(index)
            let i2 = UInt32(index + 1)
            triangleIndices.append(contentsOf: [0, i2, i1])
        }
        
        return .init(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
    
    static func generateCylinder(radius: Float,
                                 length: Float,
                                 padding: Float = 0.0,
                                 subdivision: CylinderSubdivision = .both(36, 3)) -> Submesh {
        guard padding == 0 else {
            let newRadius = radius + padding
            let newLength = length + 2 * padding
            
            return generateCylinder(radius: newRadius, length: newLength, subdivision: subdivision)
        }
         
        var body = generateCylindricalSurface(radius: radius, length: length, subdivision: subdivision)
        body.texcoords = .init(body.texcoords.lazy.scaled(y: 0.5).translated(y: 0.5))
        
        var topCover = generateCircleCover(radius: radius, subdivision: subdivision)
        topCover.texcoords.scale(0.5)
        topCover.translate(y: 0.5 * length)
        
        let bottomCover = topCover.rotated(angle: .pi, axis: .init(1, 0, 0))
        
        return body + topCover + bottomCover
    }
    
    private static func generateHollowCircleCover(outerRadius: Float,
                                                  innerRadius: Float,
                                                  axis: simd_float3.Axis = .y,
                                                  subdivision: CylinderSubdivision) -> Submesh {
        
        let rcount = subdivision.radial
        
        #if SUPPORT_DEBUG_GESTURE && !DEBUG
        guard outerRadius >= 0 && innerRadius >= 0 && outerRadius >= innerRadius && rcount >= 3 else {
            print("\(#function) returns a temporary submesh.")
            return generateHollowCircleCover(outerRadius: 1, innerRadius: 0.5, subdivision: .none)
        }
        #else
        precondition(outerRadius >= 0)
        precondition(innerRadius >= 0)
        precondition(outerRadius >= innerRadius)
        precondition(rcount >= 3)
        #endif
        
        let vertexCount = (rcount + 1) * 2
        let faceCount = rcount * 2
        let indexCount = faceCount * 3
        
        var positions = [simd_float3]()
        positions.reserveCapacity(vertexCount)
        let normal = switch axis {
        case .x: simd_float3(1, 0, 0)
        case .y: simd_float3(0, 1, 0)
        case .z: simd_float3(0, 0, 1)
        }
        let normals = [simd_float3](repeating: normal, count: vertexCount)
        var texcoords = [simd_float2]()
        texcoords.reserveCapacity(vertexCount)
        var triangleIndices = [UInt32]()
        triangleIndices.reserveCapacity(indexCount)
        
        for index in 0...rcount {
            let ratio = Float(index) / Float(rcount)
            let angle = 2.0 * .pi * ratio
            
            let direction = simd_float3(angle: angle, axis: axis)
            let innerPosition = innerRadius * direction
            let outerPosition = outerRadius * direction
            
            let radiusRatio = innerRadius / outerRadius
            let outerTexcoord = simd_float2(angle: angle, radius: 1)
            let innerTexcoord = radiusRatio * outerTexcoord
            
            positions.append(innerPosition)
            positions.append(outerPosition)
            texcoords.append(innerTexcoord)
            texcoords.append(outerTexcoord)
        }
        
        for index in 0..<rcount {
            let in0 = UInt32(index * 2)
            let out0 = UInt32(index * 2 + 1)
            let in1 = in0 + 2
            let out1 = out0 + 2
            triangleIndices.append(contentsOf: [
                in1, out1, out0,
                in1, out0, in0
            ])
        }
        
        return .init(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
    
    static func generateVolumetricCylindricalSurface(radius: Float,
                                                     length: Float,
                                                     padding: Float,
                                                     subdivision: CylinderSubdivision = .both(36, 3)) -> Submesh {
        
        let outerRadius = radius + padding
        let innerRadius = radius - padding
        let length = length + 2 * padding
        
        return generateVolumetricCylindricalSurface(outerRadius: outerRadius,
                                                    innerRadius: innerRadius,
                                                    length: length,
                                                    subdivision: subdivision)
    }
    
    static func generateVolumetricCylindricalSurface(outerRadius: Float,
                                                     innerRadius: Float,
                                                     length: Float,
                                                     subdivision: CylinderSubdivision = .both(36, 3)) -> Submesh {
        
        var outerBody = generateCylindricalSurface(radius: outerRadius, length: length, subdivision: subdivision)
        outerBody.texcoords = .init(outerBody.texcoords.lazy.scaled(y: 0.25).translated(y: 0.5))
        
        var innerBody = generateCylindricalSurface(radius: innerRadius, length: length, subdivision: subdivision).inverted
        innerBody.texcoords = .init(innerBody.texcoords.lazy.scaled(y: 0.25).translated(y: 0.75))
        
        var topCover = generateHollowCircleCover(outerRadius: outerRadius, innerRadius: innerRadius, subdivision: subdivision)
        topCover.texcoords.scale(y: 0.5)
        
        var bottomCover = topCover.rotated(angle: .pi, axis: .init(1, 0, 0))
        bottomCover.texcoords.translate(x: 0.5)
        
        topCover.translate(y: 0.5 * length)
        bottomCover.translate(y: -0.5 * length)
        
        return outerBody + innerBody + topCover + bottomCover
    }
}

typealias ConeSubdivision = CylinderSubdivision

// Cone
extension Submesh {
    
    static func generateConicalSurface(topRadius: Float,
                                       bottomRadius: Float,
                                       topHeight: Float,
                                       bottomHeight: Float,
                                       subdivision: ConeSubdivision = .both(36, 2)) -> Submesh {
        
        guard topRadius >= 0 else {
            let ratio = (topHeight - bottomHeight) / (bottomRadius - topRadius)
            let topHeight = topHeight + topRadius * ratio
            return generateConicalSurface(topRadius: 0, 
                                          bottomRadius: bottomRadius,
                                          topHeight: topHeight,
                                          bottomHeight: bottomHeight,
                                          subdivision: subdivision)
        }
        
        let rcount = UInt32(subdivision.radial)
        let lcount = UInt32(subdivision.lateral)
        
        #if SUPPORT_DEBUG_GESTURE && !DEBUG
        guard topRadius >= 0 && bottomRadius >= 0 && topRadius <= bottomRadius,
              topHeight >= bottomHeight && lcount >= 1 && rcount >= 1 else {
            print("\(#function) returns a temporary submesh.")
            return generateConicalSurface(topRadius: 0, bottomRadius: 1, length: 1, subdivision: .none)
        }
        #else
        precondition(topRadius >= 0)
        precondition(bottomRadius >= 0)
        precondition(topRadius <= bottomRadius)
        precondition(topHeight >= bottomHeight)
        precondition(lcount >= 1)
        precondition(rcount >= 3)
        #endif
        
        let vertexCount = Int((rcount + 1) * (lcount + 1))
        let faceCount = Int(2 * rcount * lcount)
        let indexCount = faceCount * 3
        
        var positions = [simd_float3]()
        positions.reserveCapacity(vertexCount)
        var normals = [simd_float3]()
        normals.reserveCapacity(vertexCount)
        var texcoords = [simd_float2]()
        texcoords.reserveCapacity(vertexCount)
        var triangleIndices = [UInt32]()
        triangleIndices.reserveCapacity(indexCount)
        
        let slope = (bottomRadius - topRadius) / (topHeight - bottomHeight)
        let cosine = 1 / sqrt(1 + slope * slope)
        
        for rindex in 0...rcount {
            let rratio = Float(rindex) / Float(rcount)
            let angle = 2.0 * .pi * rratio
            let direction = simd_float3(angle: angle, axis: .y)
            
            for lindex in 0...lcount {
                let lratio = Float(lindex) / Float(lcount)
                let radius = mix(topRadius, bottomRadius, t: lratio)
                let height = mix(topHeight, bottomHeight, t: lratio)
                let position = radius * direction + .init(0, height, 0)
                let texcoord = simd_float2(1.0 - rratio, lratio)
                
                let normal = (direction + .init(0, slope, 0)) * cosine
                
                positions.append(position)
                normals.append(normal)
                texcoords.append(texcoord)
            }
        }
        
        for rindex in 0..<rcount {
            let i0 = rindex * (lcount + 1)
            let i1 = (rindex + 1) * (lcount + 1)
            for lindex in 0..<lcount {
                let i00 = i0 + lindex
                let i01 = i0 + lindex + 1
                let i10 = i1 + lindex
                let i11 = i1 + lindex + 1
                
                triangleIndices.append(contentsOf: [
                    i10, i11, i01,
                    i10, i01, i00
                ])
            }
        }
        
        return .init(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
    
    static func generateConicalSurface(topRadius: Float,
                                       bottomRadius: Float,
                                       length: Float,
                                       subdivision: ConeSubdivision = .both(36, 2)) -> Submesh {
        return generateConicalSurface(topRadius: topRadius,
                                      bottomRadius: bottomRadius,
                                      topHeight: 0.5 * length,
                                      bottomHeight: -0.5 * length, 
                                      subdivision: subdivision)
    }
    
    static func generateCone(topRadius: Float,
                             bottomRadius: Float,
                             topHeight: Float,
                             bottomHeight: Float,
                             padding: Float = 0.0,
                             subdivision: ConeSubdivision = .both(36, 2)) -> Submesh {
        
        guard topRadius >= 0 else {
            let ratio = (topHeight - bottomHeight) / (bottomRadius - topRadius)
            let topHeight = topHeight + topRadius * ratio
            return generateCone(topRadius: 0,
                                bottomRadius: bottomRadius,
                                topHeight: topHeight,
                                bottomHeight: bottomHeight,
                                padding: padding,
                                subdivision: subdivision)
        }
        
        let t = -(bottomRadius - topRadius) / (topHeight - bottomHeight)
        let c = 1 / sqrt(1 + t * t)
        let s = -t * c
        
        let height: (_ radius: Float, _ padding: Float) -> Float = { radius, padding in
            return (radius - bottomRadius - padding * c) / t + bottomHeight + padding * s
        }
        let radius: (_ height: Float, _ padding: Float) -> Float = { height, padding in
            return (height - bottomHeight - padding * s) * t + bottomRadius + padding * c
        }
        
        var topRadius = topRadius
        var bottomRadius = bottomRadius
        var topHeight = topHeight
        var bottomHeight = bottomHeight
        
        if padding > 0 {
            topRadius = topRadius > 0 ? radius(topHeight + padding, padding) : 0
            topHeight = topRadius > 0 ? topHeight + padding : height(0, padding)
            bottomRadius = radius(bottomHeight - padding, padding)
            bottomHeight = bottomHeight - padding
            
        } else if padding < 0 {
            topHeight = topHeight + padding
            topRadius = radius(topHeight, padding)
            bottomHeight = bottomHeight - padding
            bottomRadius = radius(bottomHeight, padding)
        }
        var body = generateConicalSurface(topRadius: topRadius, bottomRadius: bottomRadius,
                                      topHeight: topHeight, bottomHeight: bottomHeight,
                                      subdivision: subdivision)
        body.texcoords = .init(body.texcoords.lazy.scaled(y: 0.5).translated(y: 0.5))
        
        var bottomCover = generateCircleCover(radius: bottomRadius, subdivision: subdivision)
        bottomCover.rotate(angle: .pi, axis: .init(1, 0, 0))
        bottomCover.texcoords = .init(bottomCover.texcoords.lazy.scaled(0.5).translated(x: 0.5))
        bottomCover.translate(y: bottomHeight)
        
        guard topRadius > 0 else {
            return body + bottomCover
        }
        
        var topCover = generateCircleCover(radius: topRadius, subdivision: subdivision)
        topCover.texcoords.scale(0.5)
        topCover.translate(y: topHeight)
        
        return body + topCover + bottomCover
    }
    
    static func generateCone(topRadius: Float,
                             bottomRadius: Float,
                             length: Float,
                             padding: Float = 0.0,
                             subdivision: ConeSubdivision = .both(36, 2)) -> Submesh {
        return generateCone(topRadius: topRadius,
                            bottomRadius: bottomRadius,
                            topHeight: 0.5 * length,
                            bottomHeight: -0.5 * length,
                            padding: padding,
                            subdivision: subdivision)
    }
    
    static func generateVolumetricConicalSurface(topRadius: Float,
                                                 bottomRadius: Float,
                                                 topHeight: Float,
                                                 bottomHeight: Float,
                                                 padding: Float,
                                                 subdivision: ConeSubdivision = .both(36, 2)) -> Submesh {
        
        guard topRadius >= 0 else {
            let ratio = (topHeight - bottomHeight) / (bottomRadius - topRadius)
            let topHeight = topHeight + topRadius * ratio
            return generateVolumetricConicalSurface(topRadius: 0,
                                                    bottomRadius: bottomRadius,
                                                    topHeight: topHeight,
                                                    bottomHeight: bottomHeight,
                                                    padding: padding,
                                                    subdivision: subdivision)
        }
        
        let t = -(bottomRadius - topRadius) / (topHeight - bottomHeight)
        let c = 1 / sqrt(1 + t * t)
        let s = -t * c
        
        guard padding >= 0 else {
            let padding = -padding
            let topHeight = topHeight - padding * (s - c)
            let topRadius = topRadius - padding * (s + c)
            let bottomHeight = bottomHeight - padding * (s + c)
            let bottomRadius = bottomRadius - padding * (c - s)
            return generateVolumetricConicalSurface(topRadius: topRadius, bottomRadius: bottomRadius,
                                                    topHeight: topHeight, bottomHeight: bottomHeight,
                                                    padding: 0.5 * padding,
                                                    subdivision: subdivision)
        }
        
        let topOuterHeight = topHeight + padding * (s + c)
        let topOuterRadius = topRadius + padding * (c - s)
        let topInnerHeight = topHeight - padding * (s - c)
        let topInnerRadius = topRadius - padding * (s + c)
        let bottomOuterHeight = bottomHeight + padding * (s - c)
        let bottomOuterRadius = bottomRadius + padding * (c + s)
        let bottomInnerHeight = bottomHeight - padding * (s + c)
        let bottomInnerRadius = bottomRadius - padding * (c - s)
        
        var outerBody = generateConicalSurface(topRadius: topOuterRadius, bottomRadius: bottomOuterRadius,
                                               topHeight: topOuterHeight, bottomHeight: bottomOuterHeight,
                                               subdivision: subdivision)
        outerBody.texcoords = .init(outerBody.texcoords.lazy.scaled(y: 0.25).translated(y: 0.5))
        
        var innerBody = generateConicalSurface(topRadius: topInnerRadius, bottomRadius: bottomInnerRadius,
                                               topHeight: topInnerHeight, bottomHeight: bottomInnerHeight,
                                               subdivision: subdivision).inverted
        innerBody.texcoords = .init(innerBody.texcoords.lazy.scaled(y: 0.25).translated(y: 0.75))
        
        var bottomCover = generateConicalSurface(topRadius: bottomInnerRadius, bottomRadius: bottomOuterRadius,
                                                 length: bottomOuterHeight - bottomInnerHeight,
                                                 subdivision: .radial(subdivision))
        bottomCover.rotate(angle: .pi, axis: .init(1, 0, 0))
        bottomCover.texcoords = .init(bottomCover.texcoords.lazy.scaled(0.5).translated(x: 0.5))
        bottomCover.translate(y: mix(bottomInnerHeight, bottomOuterHeight, t: 0.5))
        
        guard topInnerRadius > 0 else {
            return outerBody + innerBody + bottomCover
        }
        
        var topCover = generateConicalSurface(topRadius: topInnerRadius, bottomRadius: topOuterRadius,
                                              length: topOuterHeight - topInnerHeight,
                                              subdivision: .radial(subdivision)).inverted
        topCover.rotate(angle: .pi, axis: .init(1, 0, 0))
        topCover.texcoords.scale(0.5)
        topCover.translate(y: mix(topInnerHeight, topOuterHeight, t: 0.5))
        
        return outerBody + innerBody + topCover + bottomCover
    }
    
    static func generateVolumetricConicalSurface(topRadius: Float,
                                                 bottomRadius: Float,
                                                 length: Float,
                                                 padding: Float,
                                                 subdivision: ConeSubdivision = .both(36, 2)) -> Submesh {
        return generateVolumetricConicalSurface(topRadius: topRadius, bottomRadius: bottomRadius,
                                                topHeight: 0.5 * length, bottomHeight: -0.5 * length,
                                                padding: padding,
                                                subdivision: subdivision)
    }
}

enum TorusSubdivision: Equatable {
    
    case both(Int, Int)
    case toroidal(Int)
    case poloidal(Int)
    case none
    
    static func toroidal(_ subdivision: Self) -> Self {
        return .toroidal(subdivision.toroidal)
    }
    static func poloidal(_ subdivision: Self) -> Self {
        return .poloidal(subdivision.poloidal)
    }
    
    var toroidal: Int {
        switch self {
        case let .both(toroidal, _):    return toroidal
        case let .toroidal(toroidal):   return toroidal
        default:                        return 3
        }
    }
    
    var poloidal: Int {
        switch self {
        case let .both(_, poloidal):    return poloidal
        case let .poloidal(poloidal):   return poloidal
        default:                        return 3
        }
    }
}

fileprivate let _twoPi: Float = 2.0 * .pi
fileprivate let _toDegrees: Float = 180.0 / .pi
fileprivate let _toRadians: Float = .pi / 180.0

extension Float {
    static var twoPi: Float { _twoPi }
    static func radians(fromDegrees degrees: Float) -> Float { degrees * _toRadians }
    static func degrees(fromRadians radians: Float) -> Float { radians * _toDegrees }
}

// Torus
extension Submesh {
    
    private static func generateAngleSteps(beginAngle: Float, endAngle: Float, subdivision: Int) -> [Float] {
        let angleStep = .twoPi / Float(subdivision)
        
        let lowerBound = beginAngle
        let upperBound = endAngle
        
        var angles = [lowerBound]
        
        var currentAngle = lowerBound
        if fmod(currentAngle, angleStep) != 0 {
            currentAngle += angleStep - fmod(currentAngle, angleStep)
        }
        
        while currentAngle < upperBound {
            if let last = angles.last,
                last == currentAngle {
                currentAngle += angleStep
                continue
            } else {
                angles.append(currentAngle)
                currentAngle += angleStep
            }
        }
        
        if angles.last != upperBound {
            angles.append(upperBound)
        }
        
        return angles
    }

    
    static func generateToricSurface(meanRadius: Float, tubeRadius: Float,
                                     tubeBegin: Float = .zero,
                                     tubeAngle: Float = .twoPi,
                                     subdivision: TorusSubdivision = .both(36, 36)) -> Submesh {
        
        let tcount = subdivision.toroidal
        let pcount = subdivision.poloidal
        
#if SUPPORT_DEBUG_GESTURE && !DEBUG
        guard meanRadius >= 0 && tubeRadius >= 0 && tubeAngle >= 0,
              tcount >= 3 && pcount >= 3 else {
            print("\(#function) returns a temporary submesh.")
            return generateToricSurface(meanRadius: 1, tubeRadius: 1, subdivision: .none)
        }
#else
        precondition(meanRadius >= 0)
        precondition(tubeRadius >= 0)
        precondition(tubeAngle >= 0)
        precondition(tcount >= 3)
        precondition(pcount >= 3)
#endif
        
        let tubeBegin = fmod(tubeBegin.truncatingRemainder(dividingBy: .twoPi) + .twoPi, .twoPi)
        let tubeEnd = tubeBegin + tubeAngle
        let angles = generateAngleSteps(beginAngle: tubeBegin, endAngle: tubeEnd,
                                        subdivision: tcount)
        let angleCount = angles.count
        
        let vertexCount = (pcount + 1) * angleCount
        let faceCount = 2 * pcount * (angleCount - 1)
        let indexCount = faceCount * 3
        
        var positions = [simd_float3]()
        positions.reserveCapacity(vertexCount)
        var normals = [simd_float3]()
        normals.reserveCapacity(vertexCount)
        var texcoords = [simd_float2]()
        texcoords.reserveCapacity(vertexCount)
        var triangleIndices = [UInt32]()
        triangleIndices.reserveCapacity(indexCount)
        
        for tangle in angles {
            var tratio = tangle / .twoPi
            if tratio > 1.0 {
                tratio -= 1.0
            }
            
            for pindex in 0...pcount {
                let pratio = Float(pindex) / Float(pcount)
                let pangle = .twoPi * pratio
                
                let tubeDirection = simd_float3(angle: tangle, axis: .y)
                let tubeCenter = meanRadius * tubeDirection
                let normal = cos(pangle) * tubeDirection + sin(pangle) * .init(0, 1, 0)
                let position = tubeCenter + tubeRadius * normal
                let texcoord = simd_float2(tratio, pratio)
                
                positions.append(position)
                normals.append(normal)
                texcoords.append(texcoord)
            }
        }
        
        let stride = pcount + 1
        for tIndex in angles.indices.dropLast() {
            for pIndex in 0..<pcount {
                let bottomRightIndex = UInt32(tIndex * stride + pIndex)
                let topRightIndex = bottomRightIndex + 1
                let bottomLeftIndex = UInt32((tIndex + 1) * stride + pIndex)
                let topLeftIndex = bottomLeftIndex + 1
                
                triangleIndices.append(contentsOf: [
                    topLeftIndex, bottomLeftIndex, bottomRightIndex,
                    topLeftIndex, bottomRightIndex, topRightIndex
                ])
            }
        }
        
        return .init(positions: positions, normals: normals, texcoords: texcoords, triangleIndices: triangleIndices)
    }
    
    static func generateTorus(meanRadius: Float,
                              tubeRadius: Float,
                              tubeBegin: Float = .zero,
                              tubeAngle: Float = .twoPi,
                              padding: Float = 0.0,
                              subdivision: TorusSubdivision = .both(36, 36)) -> Submesh {
        
        let tubeAngle = min(max(tubeAngle, .zero), .twoPi)
        let tubeEnd = tubeBegin + tubeAngle
        
        guard padding == 0 else {
            let tubeRadius = max(tubeRadius + padding, 0)
            let angleOffset = tubeAngle == .twoPi ? .zero : (padding / meanRadius)
            let tubeBegin = tubeBegin - angleOffset
            let tubeAngle = tubeAngle + angleOffset * 2
            return generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                 tubeBegin: tubeBegin, tubeAngle: tubeAngle,
                                 subdivision: subdivision)
        }
        
        var surface = generateToricSurface(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                           tubeBegin: tubeBegin, tubeAngle: tubeAngle,
                                           subdivision: subdivision)
        surface.texcoords = .init(surface.texcoords.lazy.scaled(y: 0.5).translated(y: 0.5))
        
        guard tubeAngle < .twoPi else {
            return surface
        }
        
        var beginCover = generateCircleCover(radius: tubeRadius, axis: .z, subdivision: .radial(subdivision.poloidal))
        var endCover = beginCover
        
        beginCover.texcoords.scale(y: 0.5)
        let beginOrientation = simd_quatf(from: .init(-1, 0, 0), to: .init(angle: tubeBegin, axis: .y))
        beginCover.rotate(beginOrientation)
        beginCover.translate(.init(angle: tubeBegin, radius: meanRadius, axis: .y))
        
        endCover.texcoords = .init(endCover.texcoords.lazy.scaled(0.5).translated(x: 0.5))
        let endOrientation = simd_quatf(from: .init(1, 0, 0), to: .init(angle: tubeEnd, axis: .y))
        endCover.rotate(endOrientation)
        endCover.translate(.init(angle: tubeEnd, radius: meanRadius, axis: .y))
        
        return surface + beginCover + endCover
    }
    
    static func generateVolumetricToricSurface(meanRadius: Float,
                                               tubeRadius: Float,
                                               tubeBegin: Float = .zero,
                                               tubeAngle: Float = .twoPi,
                                               padding: Float,
                                               subdivision: TorusSubdivision = .both(36, 36)) -> Submesh {
        
        var tubeAngle = min(max(tubeAngle, .zero), .twoPi)
        
        guard padding >= 0 else {
            let padding = -padding
            let tubeRadius = tubeRadius - padding
            return generateVolumetricToricSurface(meanRadius: meanRadius, 
                                                  tubeRadius: tubeRadius - padding,
                                                  tubeBegin: tubeBegin,
                                                  tubeAngle: tubeAngle,
                                                  padding: 0.5 * padding,
                                                  subdivision: subdivision)
        }
        
        let outerTubeRadius = tubeRadius + padding
        let innerTubeRadius = tubeRadius - padding
        let angleOffset = padding / meanRadius
        let tubeBegin = tubeBegin - angleOffset
        tubeAngle = tubeAngle + angleOffset * 2
        let tubeEnd = tubeBegin + tubeAngle
        
        guard tubeAngle < .twoPi else {
            
            return generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                 tubeBegin: tubeBegin, tubeAngle: tubeAngle,
                                 padding: padding,
                                 subdivision: subdivision)
        }
        
        var outerSurface = generateToricSurface(meanRadius: meanRadius, tubeRadius: outerTubeRadius,
                                                tubeBegin: tubeBegin, tubeAngle: tubeAngle,
                                                subdivision: subdivision)
        outerSurface.texcoords = .init(outerSurface.texcoords.lazy.scaled(y: 0.25).translated(y: 0.5))
        
        var innerSurface = generateToricSurface(meanRadius: meanRadius, tubeRadius: innerTubeRadius,
                                                tubeBegin: tubeBegin, tubeAngle: tubeAngle,
                                                subdivision: subdivision).inverted
        innerSurface.texcoords = .init(innerSurface.texcoords.lazy.scaled(y: 0.25).translated(y: 0.75))
        
        var beginCover = generateHollowCircleCover(outerRadius: outerTubeRadius,
                                                   innerRadius: innerTubeRadius,
                                                   axis: .z,
                                                   subdivision: .radial(subdivision.poloidal))
        var endCover = beginCover
        
        beginCover.texcoords.scale(y: 0.5)
        let beginOrientation = simd_quatf(from: .init(-1, 0, 0), to: .init(angle: tubeBegin, axis: .y))
        beginCover.rotate(beginOrientation)
        beginCover.translate(.init(angle: tubeBegin, radius: meanRadius, axis: .y))
        
        endCover.texcoords = .init(endCover.texcoords.lazy.scaled(0.5).translated(x: 0.5))
        let endOrientation = simd_quatf(from: .init(1, 0, 0), to: .init(angle: tubeEnd, axis: .y))
        endCover.rotate(endOrientation)
        endCover.translate(.init(angle: tubeEnd, radius: meanRadius, axis: .y))
        
        return outerSurface + innerSurface + beginCover + endCover
    }
}

func mix(_ a: Float, _ b: Float, t: Float) -> Float {
    return a * (1 - t) + b * t
}
