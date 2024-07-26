//
//  simd.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import simd

extension simd_quatf {
    var eulerAngles: SIMD3<Float> {
        let ysqr = self.imag.y * self.imag.y
        
        let t0 = 2.0 * (self.real * self.imag.x + self.imag.y * self.imag.z)
        let t1 = 1.0 - 2.0 * (self.imag.x * self.imag.x + ysqr)
        let roll = atan2(t0, t1)
        
        let t2 = 2.0 * (self.real * self.imag.y - self.imag.z * self.imag.x)
        let pitch: Float
        if t2 > 1.0 {
            pitch = .pi / 2.0 // clamp to 90 degrees
        } else if t2 < -1.0 {
            pitch = -.pi / 2.0 // clamp to -90 degrees
        } else {
            pitch = asin(t2)
        }
        
        let t3 = 2.0 * (self.real * self.imag.z + self.imag.x * self.imag.y)
        let t4 = 1.0 - 2.0 * (ysqr + self.imag.z * self.imag.z)
        let yaw = atan2(t3, t4)
        
        return SIMD3<Float>(roll, pitch, yaw)
    }
}

extension simd_float4x4 {
    
    var basisX: simd_float3 {
        get { simd_make_float3(columns.0) }
        set { columns.0 = simd_float4(newValue, columns.0.w) }
    }
    
    var basisY: simd_float3 {
        get { simd_make_float3(columns.1) }
        set { columns.1 = simd_float4(newValue, columns.1.w) }
    }
    
    var basisZ: simd_float3 {
        get { simd_make_float3(columns.2) }
        set { columns.2 = simd_float4(newValue, columns.2.w) }
    }
    
    var position: simd_float3 {
        get { simd_make_float3(columns.3) }
        set { columns.3 = simd_float4(newValue, columns.3.w) }
    }
    
    /// makes an extrinsic matrix that contains an object's orientation and location.
    static func extrinsics(xAxis: simd_float3,
                           yAxis: simd_float3,
                           zAxis: simd_float3,
                           position: simd_float3 = .zero) -> simd_float4x4 {
        return .init(.init(xAxis, 0),
                     .init(yAxis, 0),
                     .init(zAxis, 0),
                     .init(position, 1))
    }
    
    /// makes an extrinsic matrix that contains an object's location.
    static func extrinsics(position: simd_float3) -> simd_float4x4 {
        return .init(.init(1, 0, 0, 0),
                     .init(0, 1, 0, 0),
                     .init(0, 0, 1, 0),
                     .init(position, 1))
    }
    
    /// makes an extrinsic matrix that contains an object's orientation and location.
    /// - note: the Y axis and Z axis are arbitrarily determined by attempting cross products with the given `xAxis`.
    static func extrinsics(xAxis: simd_float3, position: simd_float3 = .zero) -> simd_float4x4 {
        let xAxis = normalize(xAxis)
        var yAxis = simd_float3(0, 1, 0)
        var zAxis = simd_float3(0, 0, 1)
        zAxis = if xAxis != yAxis {
            normalize(cross(xAxis, yAxis))
        } else {
            normalize(cross(xAxis, zAxis))
        }
        yAxis = normalize(cross(zAxis, xAxis))
        return .extrinsics(xAxis: xAxis, yAxis: yAxis, zAxis: zAxis, position: position)
    }
    
    /// makes an extrinsic matrix that contains an object's orientation and location.
    /// - note: the X axis and Z axis are arbitrarily determined by attempting cross products with the given `yAxis`.
    static func extrinsics(yAxis: simd_float3, position: simd_float3 = .zero) -> simd_float4x4 {
        var xAxis = simd_float3(1, 0, 0)
        let yAxis = normalize(yAxis)
        var zAxis = simd_float3(0, 0, 1)
        xAxis = if yAxis != zAxis {
            normalize(cross(yAxis, zAxis))
        } else {
            normalize(cross(yAxis, xAxis))
        }
        zAxis = normalize(cross(xAxis, yAxis))
        return .extrinsics(xAxis: xAxis, yAxis: yAxis, zAxis: zAxis, position: position)
    }
    
    /// makes an extrinsic matrix that contains an object's orientation and location.
    /// - note: the X axis and Y axis are arbitrarily determined by attempting cross products with the given `zAxis`.
    static func extrinsics(zAxis: simd_float3, position: simd_float3 = .zero) -> simd_float4x4 {
        var xAxis = simd_float3(1, 0, 0)
        var yAxis = simd_float3(0, 1, 0)
        let zAxis = normalize(zAxis)
        yAxis = if zAxis != xAxis {
            normalize(cross(zAxis, xAxis))
        } else {
            normalize(cross(zAxis, yAxis))
        }
        xAxis = normalize(cross(yAxis, zAxis))
        return .extrinsics(xAxis: xAxis, yAxis: yAxis, zAxis: zAxis, position: position)
    }
    
    /// makes a transformation matrix that converts coordinates to a model coordinate system defined by `xAxis`, `yAxis`, `zAxis`, and `origin`.
    static func transform(xAxis: simd_float3,
                          yAxis: simd_float3,
                          zAxis: simd_float3,
                          origin: simd_float3 = .zero) -> simd_float4x4 {
        return .init(rows: [.init(xAxis, -dot(origin, xAxis)),
                            .init(yAxis, -dot(origin, yAxis)),
                            .init(zAxis, -dot(origin, zAxis)),
                            .init(0, 0, 0, 1)])
    }
}


extension simd_float2 {
    
    init(angle: Float, radius: Float = 1.0) {
        self.init(x: radius * cos(angle), y: radius * sin(angle))
    }
}

extension simd_float3 {
    
    enum Axis {
        case x
        case y
        case z
    }
    
    init(theta: Float, phi: Float, radius: Float = 1.0, polarAxis: Axis = .y) {
        
        let x = radius * sin(theta) * cos(phi)
        let y = radius * cos(theta)
        let z = radius * sin(theta) * sin(phi)
        
        switch polarAxis {
        case .x: self.init(y, z, x)
        case .y: self.init(x, y, z)
        case .z: self.init(z, x, y)
        }
    }
    
    init(angle: Float, radius: Float = 1.0, height: Float = 0.0, axis: Axis) {
        
        let x = radius * cos(angle)
        let z = radius * sin(angle)
        
        switch axis {
        case .x: self.init(height, z, x)
        case .y: self.init(x, height, z)
        case .z: self.init(z, x, height)
        }
    }
}

extension LazySequenceProtocol where Element == simd_float2 {
    
    func translated(_ offset: simd_float2) -> LazyMapSequence<Elements, simd_float2> {
        return map { $0 + offset }
    }
    
    func translated(x: Float, y: Float = 0.0) -> LazyMapSequence<Elements, simd_float2> {
        return translated(.init(x, y))
    }
    
    func translated(y: Float) -> LazyMapSequence<Elements, simd_float2> {
        return translated(x: 0, y: y)
    }
    
    func scaled(_ factors: simd_float2) -> LazyMapSequence<Elements, simd_float2> {
        return map { $0 * factors }
    }
    
    func scaled(_ factor: Float) -> LazyMapSequence<Elements, simd_float2> {
        return scaled(.init(repeating: factor))
    }
    
    func scaled(x: Float, y: Float = 1.0) -> LazyMapSequence<Elements, simd_float2> {
        return scaled(.init(x, y))
    }
    
    func scaled(y: Float) -> LazyMapSequence<Elements, simd_float2> {
        return scaled(x: 1, y: y)
    }
    
    func rotated(angle: Float) -> LazyMapSequence<Elements, simd_float2> {
        let c = cos(angle)
        let s = sin(angle)
        let rotation = simd_float2x2(.init(c, s), .init(-s, c))
        return map { rotation * $0 }
    }
}

extension Array where Element == simd_float2 {
    
    mutating func translate(_ offset: simd_float2) {
        self = map { $0 + offset }
    }
    
    func translated(_ offset: simd_float2) -> Self {
        var this = self
        this.translate(offset)
        return this
    }
    
    mutating func translate(x: Float, y: Float = 0.0) {
        translate(.init(x, y))
    }
    
    func translated(x: Float, y: Float = 0.0) -> Self {
        return translated(.init(x, y))
    }
    
    mutating func translate(y: Float) {
        translate(x: 0, y: y)
    }
    
    func translated(y: Float) -> Self {
        return translated(x: 0, y: y)
    }
    
    mutating func scale(_ factors: simd_float2) {
        self = map { $0 * factors }
    }
    
    func scaled(_ factors: simd_float2) -> Self {
        var this = self
        this.scale(factors)
        return this
    }
    
    mutating func scale(_ factor: Float) {
        scale(.init(repeating: factor))
    }
    
    func scaled(_ factor: Float) -> Self {
        return scaled(.init(repeating: factor))
    }
    
    mutating func scale(x: Float, y: Float = 1.0) {
        scale(.init(x, y))
    }
    
    func scaled(x: Float, y: Float = 1.0) -> Self {
        return scaled(.init(x, y))
    }
    
    mutating func scale(y: Float) {
        scale(x: 1, y: y)
    }
    
    func scaled(y: Float) -> Self {
        return scaled(x: 1, y: y)
    }
    
    mutating func rotate(angle: Float) {
        let c = cos(angle)
        let s = sin(angle)
        let rotation = simd_float2x2(.init(c, s), .init(-s, c))
        self = map { rotation * $0 }
    }
    
    func rotated(angle: Float) -> Self {
        var this = self
        this.rotate(angle: angle)
        return this
    }
}

extension LazySequenceProtocol where Element == simd_float3 {
    
    func translated(_ offset: simd_float3) -> LazyMapSequence<Elements, simd_float3> {
        return map { $0 + offset }
    }
    
    func translated(x: Float, y: Float = 0.0, z: Float = 0.0) -> LazyMapSequence<Elements, simd_float3> {
        return translated(.init(x, y, z))
    }
    
    func translated(y: Float, z: Float = 0.0) -> LazyMapSequence<Elements, simd_float3> {
        return translated(x: 0, y: y, z: z)
    }
    
    func translated(z: Float) -> LazyMapSequence<Elements, simd_float3> {
        return translated(x: 0, y: 0, z: z)
    }
    
    func scaled(_ factors: simd_float3) -> LazyMapSequence<Elements, simd_float3> {
        return map { $0 * factors }
    }
    
    func scaled(_ factor: Float) -> LazyMapSequence<Elements, simd_float3> {
        return scaled(.init(repeating: factor))
    }
    
    func scaled(x: Float, y: Float = 1.0, z: Float = 1.0) -> LazyMapSequence<Elements, simd_float3> {
        return scaled(.init(x, y, z))
    }
    
    func scaled(y: Float, z: Float = 1.0) -> LazyMapSequence<Elements, simd_float3> {
        return scaled(x: 1, y: y, z: z)
    }
    
    func scaled(z: Float) -> LazyMapSequence<Elements, simd_float3> {
        return scaled(x: 1, y: 1, z: z)
    }
    
    func rotated(_ rotation: simd_quatf) -> LazyMapSequence<Elements, simd_float3> {
        return map { rotation.act($0) }
    }
    
    func rotated(angle: Float, axis: simd_float3) -> LazyMapSequence<Elements, simd_float3> {
        return rotated(.init(angle: angle, axis: axis))
    }
    
    func rotated(from: simd_float3, to: simd_float3) -> LazyMapSequence<Elements, simd_float3> {
        return rotated(.init(from: from, to: to))
    }
}

extension Array where Element == simd_float3 {
    
    mutating func translate(_ offset: simd_float3) {
        self = map { $0 + offset }
    }
    
    func translated(_ offset: simd_float3) -> Self {
        var this = self
        this.translate(offset)
        return this
    }
    
    mutating func translate(x: Float, y: Float = 0.0, z: Float = 0.0) {
        translate(.init(x, y, z))
    }
    
    func translated(x: Float, y: Float = 0.0, z: Float = 0.0) -> Self {
        return translated(.init(x, y, z))
    }
    
    mutating func translate(y: Float, z: Float = 0.0) {
        translate(x: 0, y: y, z: z)
    }
    
    func translated(y: Float, z: Float = 0.0) -> Self {
        return translated(x: 0, y: y, z: z)
    }
    
    mutating func translate(z: Float) {
        translate(x: 0, y: 0, z: z)
    }
    
    func translated(z: Float) -> Self {
        return translated(x: 0, y: 0, z: z)
    }
    
    mutating func scale(_ factors: simd_float3) {
        self = map { $0 * factors }
    }
    
    func scaled(_ factors: simd_float3) -> Self {
        var this = self
        this.scale(factors)
        return this
    }
    
    mutating func scale(_ factor: Float) {
        scale(.init(repeating: factor))
    }
    
    func scaled(_ factor: Float) -> Self {
        return scaled(.init(repeating: factor))
    }
    
    mutating func scale(x: Float, y: Float = 1.0, z: Float = 1.0) {
        scale(.init(x, y, z))
    }
    
    func scaled(x: Float, y: Float = 1.0, z: Float = 1.0) -> Self {
        return scaled(.init(x, y, z))
    }
    
    mutating func scale(y: Float, z: Float = 1.0) {
        scale(x: 1, y: y, z: z)
    }
    
    func scaled(y: Float, z: Float = 1.0) -> Self {
        return scaled(x: 1, y: y, z: z)
    }
    
    mutating func scale(z: Float) {
        scale(x: 1, y: 1, z: z)
    }
    
    func scaled(z: Float) -> Self {
        return scaled(x: 1, y: 1, z: z)
    }
    
    mutating func rotate(_ rotation: simd_quatf) {
        self = map { rotation.act($0) }
    }
    
    func rotated(_ rotation: simd_quatf) -> Self {
        var this = self
        this.rotate(rotation)
        return this
    }
    
    mutating func rotate(angle: Float, axis: simd_float3) {
        rotate(.init(angle: angle, axis: axis))
    }
    
    func rotated(angle: Float, axis: simd_float3) -> Self {
        return rotated(.init(angle: angle, axis: axis))
    }
    
    mutating func rotate(from: simd_float3, to: simd_float3) {
        rotate(.init(from: from, to: to))
    }
    
    func rotated(from: simd_float3, to: simd_float3) -> Self {
        return rotated(.init(from: from, to: to))
    }
}
