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

fileprivate let torusOcclusionDepth: Float = 0.0001
fileprivate let occlusionMaterials = [OcclusionMaterial()]
fileprivate let wireframeMaterials = {
    var material = UnlitMaterial(color: .black)
    material.triangleFillMode = .lines
    return [material]
}()
fileprivate let surfaceMaterials = [UnlitMaterial(color: .yellow.withAlphaComponent(0.2))]
fileprivate let outlineMaterials = [UnlitMaterial(color: .black)]

@MainActor
final class TorusEntity: GeometryEntity {
    
    enum Shape: Equatable {
        case volume
        case surface
    }
    
    struct Intrinsics: Equatable {
        var meanRadius: Float
        var tubeRadius: Float
        var tubeBegin: Angle
        var tubeAngle: Angle
        var outlineWidth: Float
        var shape: Shape
        var subdivision: TorusSubdivision
        init(meanRadius: Float = 1,
             tubeRadius: Float = 1,
             tubeBegin: Angle = .zero,
             tubeAngle: Angle = .degrees(360),
             outlineWidth: Float = 0.005,
             shape: Shape = .volume,
             subdivision: TorusSubdivision = .both(36, 36)) {
            self.meanRadius = meanRadius
            self.tubeRadius = tubeRadius
            self.tubeBegin = tubeBegin
            self.tubeAngle = tubeAngle
            self.outlineWidth = outlineWidth
            self.shape = shape
            self.subdivision = subdivision
        }
    }
    private(set) var intrinsics: Intrinsics
    
    let occlusion: ModelEntity
    let wireframe: ModelEntity
    let surface: ModelEntity
    let outline: ModelEntity
    
    required init() {
        
        let intrinsics = Intrinsics()
        let dummy = MeshResource.generatePlane(width: 1, depth: 1)
        let occlusion = ModelEntity(mesh: dummy, materials: occlusionMaterials)
        let wireframe = ModelEntity(mesh: dummy, materials: wireframeMaterials)
        let surface = ModelEntity(mesh: dummy, materials: surfaceMaterials)
        let outline = ModelEntity(mesh: dummy, materials: outlineMaterials)
        updateModelEntities(intrinsics, occlusion, wireframe, surface, outline)
        
        self.intrinsics = intrinsics
        self.occlusion = occlusion
        self.wireframe = wireframe
        self.surface = surface
        self.outline = outline
        super.init()
        
        addChild(occlusion)
        addChild(wireframe)
        addChild(surface)
        addChild(outline)
        
        #if SUPPORT_DEBUG_GESTURE
        let threshold = intrinsics.meanRadius * intrinsics.meanRadius
        let meshPoints = Submesh.generateToricSurface(meanRadius: intrinsics.meanRadius,
                                                      tubeRadius: intrinsics.tubeRadius,
                                                      subdivision: intrinsics.subdivision).positions.filter { length_squared($0) >= threshold }
        components.set(CollisionComponent(shapes: [.generateConvex(from: meshPoints)]))
        components.set(InputTargetComponent())
        components.set(DebugGestureComponent())
        #endif
    }
    
    convenience init(meanRadius: Float,
                     tubeRadius: Float,
                     tubeBegin: Angle = .zero,
                     tubeAngle: Angle = .degrees(360),
                     outlineWidth: Float = 0.005,
                     shape: Shape = .volume,
                     subdivision: TorusSubdivision = .both(36, 36)) {
        self.init()
        update { intrinsics in
            intrinsics.meanRadius = meanRadius
            intrinsics.tubeRadius = tubeRadius
            intrinsics.tubeBegin = tubeBegin
            intrinsics.tubeAngle = tubeAngle
            intrinsics.outlineWidth = outlineWidth
            intrinsics.shape = shape
            intrinsics.subdivision = subdivision
        }
    }
    
    @MainActor
    func update(block: (inout Intrinsics) -> Void) {
        
        var intrinsics = self.intrinsics
        block(&intrinsics)
        
        guard intrinsics != self.intrinsics else { return }
        defer { self.intrinsics = intrinsics }
        
        updateModelEntities(intrinsics, occlusion, wireframe, surface, outline)
        
        #if SUPPORT_DEBUG_GESTURE
        let threshold = intrinsics.meanRadius * intrinsics.meanRadius
        let meshPoints = Submesh.generateToricSurface(meanRadius: intrinsics.meanRadius,
                                                      tubeRadius: intrinsics.tubeRadius,
                                                      subdivision: intrinsics.subdivision).positions.filter { length_squared($0) >= threshold }
        components.set(CollisionComponent(shapes: [.generateConvex(from: meshPoints)]))
        #endif
    }
    
    override func enableOutline(_ visible: Bool) {
        occlusion.isEnabled = visible
        wireframe.isEnabled = visible
        outline.isEnabled = visible
    }
}

fileprivate func updateModelEntities(
    _ intrinsics: TorusEntity.Intrinsics,
    _ occlusion: ModelEntity,
    _ wireframe: ModelEntity,
    _ surface: ModelEntity,
    _ outline: ModelEntity
) {
    
    let meanRadius = intrinsics.meanRadius
    let tubeRadius = intrinsics.tubeRadius
    let tubeBegin = intrinsics.tubeBegin
    let tubeAngle = intrinsics.tubeAngle
    let outlineWidth = intrinsics.outlineWidth
    let shape = intrinsics.shape
    let subdivision = intrinsics.subdivision
    
    switch shape {
    case .volume:
        
        occlusion.model?.mesh = .generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                               tubeBegin: tubeBegin, tubeAngle: tubeAngle,
                                               padding: -torusOcclusionDepth,
                                               subdivision: subdivision)
        let mesh = MeshResource.generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                              tubeBegin: tubeBegin, tubeAngle: tubeAngle,
                                              subdivision: subdivision)
        wireframe.model?.mesh = mesh
        surface.model?.mesh = mesh
        outline.model?.mesh = .generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                             tubeBegin: tubeBegin, tubeAngle: tubeAngle,
                                             padding: outlineWidth,
                                             subdivision: subdivision,
                                             insideOut: true)
        
    case .surface:
        
        occlusion.model?.mesh = .generateVolumetricToricSurface(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                                                tubeBegin: tubeBegin, tubeAngle: tubeAngle,
                                                                padding: -torusOcclusionDepth,
                                                                subdivision: subdivision)
        
        let mesh = MeshResource.generateToricSurface(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                                     tubeBegin: tubeBegin, tubeAngle: tubeAngle,
                                                     subdivision: subdivision)
        wireframe.model?.mesh = mesh
        surface.model?.mesh = mesh
        
        outline.model?.mesh = .generateVolumetricToricSurface(meanRadius: meanRadius, tubeRadius: tubeRadius,
                                                              tubeBegin: tubeBegin, tubeAngle: tubeAngle,
                                                              padding: outlineWidth,
                                                              subdivision: subdivision,
                                                              insideOut: true)
    }
}
