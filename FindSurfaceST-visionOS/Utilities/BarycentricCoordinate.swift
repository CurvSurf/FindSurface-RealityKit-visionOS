//
//  BarycentricCoordinate.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 7/12/24.
//

import Foundation
import simd

func barycentricCoordinate(_ a: simd_float3,
                           _ b: simd_float3,
                           _ c: simd_float3,
                           _ p: simd_float3) -> simd_float3 {
    
    let v0 = b - a
    let v1 = c - a
    let v2 = p - a
    
    let dot00 = dot(v0, v0)
    let dot01 = dot(v0, v1)
    let dot11 = dot(v1, v1)
    let dot20 = dot(v2, v0)
    let dot21 = dot(v2, v1)
    
    let denom = dot00 * dot11 - dot01 * dot01
    let u = (dot11 * dot20 - dot01 * dot21) / denom
    let v = (dot00 * dot21 - dot01 * dot20) / denom
    let w = 1.0 - u - v
    
    return simd_float3(u, v, w)
}

func hitPlane(_ rayOrigin: simd_float3, _ rayDirection: simd_float3, _ planeCenter: simd_float3, _ planeNormal: simd_float3) -> simd_float3? {
    
    guard dot(planeNormal, rayDirection) != 0 else { return nil }
    
    // dot(planeNormal, (X - planeCenter) = 0
    // X = rayOrigin + rayDirection * t
    // dot(planeNormal, (rayOrigin + rayDirection * t - planeCenter)) = 0
    // dot(planeNormal, rayOrigin - planeCenter) + dot(planeNormal, rayDirection) * t = 0
    let t = dot(planeNormal, planeCenter - rayOrigin) / dot(planeNormal, rayDirection)
    return rayOrigin + rayDirection * t
}
