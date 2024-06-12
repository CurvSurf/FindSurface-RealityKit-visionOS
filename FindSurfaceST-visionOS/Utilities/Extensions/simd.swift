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

