//
//  Material.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import RealityKit

protocol HasTriangleFillMode: Material {
    
    typealias TriangleFillMode = MaterialParameterTypes.TriangleFillMode
    
    var triangleFillMode: TriangleFillMode { get set }
}

extension HasTriangleFillMode {
    
    var wireframe: Self {
        var material = self
        material.triangleFillMode = .lines
        return material
    }
}

extension UnlitMaterial: HasTriangleFillMode {}
extension SimpleMaterial: HasTriangleFillMode {}
extension VideoMaterial: HasTriangleFillMode {}
extension PortalMaterial: HasTriangleFillMode {}
extension ShaderGraphMaterial: HasTriangleFillMode {}
extension PhysicallyBasedMaterial: HasTriangleFillMode {}

extension Array where Element == (any Material) {
    
    static var mesh: [any Material] {
        return [UnlitMaterial(color: .blue).wireframe]
    }
    
    static var plane: [any Material] {
        return [UnlitMaterial(color: .red)]
    }
    
    static var sphere: [any Material] {
        return [UnlitMaterial(color: .green)]
    }
    
    static var cylinder: [any Material] {
        return [UnlitMaterial(color: .purple)]
    }
    
    static var cone: [any Material] {
        return [UnlitMaterial(color: .cyan)]
    }
    
    static var torus: [any Material] {
        return [UnlitMaterial(color: .yellow)]
    }
}
