//
//  TorusEntity.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/25/24.
//

import Foundation
import RealityKit
import Algorithms
import SwiftUI

@MainActor
final class TorusEntity: GeometryEntity {
    
    enum Shape: Equatable {
        case fullVolume
        case partialVolume(Angle, Angle)
        case partialSurface(Angle, Angle)
    }
    
    struct Intrinsics: Equatable {
        var meanRadius: Float
        var tubeRadius: Float
        var outlineWidth: Float
        var shape: Shape
        init(meanRadius: Float = 1, tubeRadius: Float = 1, outlineWidth: Float = 0.005,
             shape: Shape = .fullVolume) {
            self.meanRadius = meanRadius
            self.tubeRadius = tubeRadius
            self.outlineWidth = outlineWidth
            self.shape = shape
        }
    }
    private var intrinsics = Intrinsics()
    
    let occlusion: ModelEntity
    let wireframe: ModelEntity
    let surface: ModelEntity
    let outline: ModelEntity
    
    convenience init(meanRadius: Float, tubeRadius: Float, outlineWidth: Float = 0.005,
                     shape: Shape = .fullVolume) {
        self.init()
        update { intrinsics in
            intrinsics.meanRadius = meanRadius
            intrinsics.tubeRadius = tubeRadius
            intrinsics.outlineWidth = outlineWidth
            intrinsics.shape = shape
        }
    }
    
    override func enableOutline(_ visible: Bool) {
        occlusion.isEnabled = visible
        wireframe.isEnabled = visible
        outline.isEnabled = visible
    }
    
    required init() {
        
        let occlusion = {
            let mesh = MeshResource.generateTorus(meanRadius: 1, tubeRadius: 1 - 0.0001)
            let material = OcclusionMaterial()
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let wireframe = {
            let mesh = MeshResource.generateTorus(meanRadius: 1, tubeRadius: 1)
            var material = UnlitMaterial(color: .black)
            material.triangleFillMode = .lines
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let surface = {
            let mesh = MeshResource.generateTorus(meanRadius: 1, tubeRadius: 1)
            let material = UnlitMaterial(color: .yellow.withAlphaComponent(0.2))
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let outline = {
            let mesh = MeshResource.generateTorus(meanRadius: 1, tubeRadius: 1 + 0.005, useClockwiseTriangleWinding: true)
            let material = UnlitMaterial(color: .black)
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        self.occlusion = occlusion
        self.wireframe = wireframe
        self.surface = surface
        self.outline = outline
        super.init()
        
        addChild(occlusion)
        addChild(wireframe)
        addChild(surface)
        addChild(outline)
        
        update(block: { _ in })
    }
    
    @MainActor
    func update(block: (inout Intrinsics) -> Void) {
        
        var intrinsics = self.intrinsics
        block(&intrinsics)
        
        guard intrinsics != self.intrinsics else { return }
        
        let meanRadius = intrinsics.meanRadius
        let tubeRadius = intrinsics.tubeRadius
        let outlineWidth = intrinsics.outlineWidth
        var shape = intrinsics.shape
        if case let .partialVolume(begin, end) = shape,
           abs(end.degrees - begin.degrees) > 360 {
            shape = .fullVolume
        } else if case let .partialSurface(begin, end) = shape,
                  abs(end.degrees - begin.degrees) > 360 {
            shape = .fullVolume
        }
        
        switch shape {
        case .fullVolume:
            occlusion.model?.mesh = .generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius - 0.0001)
            let mesh = MeshResource.generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius)
            wireframe.model?.mesh = mesh
            surface.model?.mesh = mesh
            outline.model?.mesh = .generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius + outlineWidth,
                                                 useClockwiseTriangleWinding: true)
            
        case let .partialVolume(beginAngle, endAngle):
            occlusion.model?.mesh = .generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius - 0.001,
                                                   beginAngle: Angle(degrees: beginAngle.degrees + 1), endAngle: Angle(degrees: endAngle.degrees - 1))
            let mesh = MeshResource.generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                                  beginAngle: beginAngle, endAngle: endAngle)
            wireframe.model?.mesh = mesh
            surface.model?.mesh = mesh
            outline.model?.mesh = .generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius + outlineWidth,
                                                 beginAngle: Angle(degrees: beginAngle.degrees - 1), endAngle: Angle(degrees: endAngle.degrees + 1),
                                                 useClockwiseTriangleWinding: true)
        case let .partialSurface(beginAngle, endAngle):
            occlusion.model?.mesh = .generateVolumetricToricSurface(meanRadius: meanRadius, tubeRadius: tubeRadius - 0.001,
                                                                    beginAngle: Angle(degrees: beginAngle.degrees + 1), endAngle: Angle(degrees: endAngle.degrees - 1),
                                                                    thickness: 0.001)
            let mesh = MeshResource.generateToricSurface(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                                         beginAngle: beginAngle, endAngle: endAngle)
            wireframe.model?.mesh = mesh
            surface.model?.mesh = mesh
            outline.model?.mesh = .generateVolumetricToricSurface(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                                                  beginAngle: Angle(degrees: beginAngle.degrees - 1), endAngle: Angle(degrees: endAngle.degrees + 1),
                                                                  thickness: outlineWidth,
                                                                  useClockwiseTriangleWinding: true)
        }
        
        self.intrinsics = intrinsics
    }
}

