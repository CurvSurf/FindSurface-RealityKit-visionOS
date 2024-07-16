//
//  ConeEntity.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/25/24.
//

import Foundation
import RealityKit

@MainActor
final class ConeEntity: GeometryEntity {
    
    enum Shape: Equatable {
        case volume
        case surface
    }
    
    struct Intrinsics: Equatable {
        var topRadius: Float
        var bottomRadius: Float
        var height: Float
        var outlineWidth: Float
        var shape: Shape
        init(topRadius: Float = 0, bottomRadius: Float = 1, height: Float = 1, outlineWidth: Float = 0.005, shape: Shape = .volume) {
            self.topRadius = topRadius
            self.bottomRadius = bottomRadius
            self.height = height
            self.outlineWidth = outlineWidth
            self.shape = shape
        }
    }
    private(set) var intrinsics = Intrinsics()
    
    private let occlusion: ModelEntity
    private let wireframe: ModelEntity
    private let surface: ModelEntity
    private let outline: ModelEntity
    
    convenience init(topRadius: Float, bottomRadius: Float, height: Float, outlineWidth: Float = 0.005, shape: Shape = .volume) {
        self.init()
        update { intrinsics in
            intrinsics.topRadius = topRadius
            intrinsics.bottomRadius = bottomRadius
            intrinsics.height = height
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
            let mesh = MeshResource.generateCone(topRadius: 0 - 0.0001, bottomRadius: 1 - 0.0001,
                                                 height: 1 - 0.0002)
            let material = OcclusionMaterial()
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let wireframe = {
            let mesh = MeshResource.generateCone(topRadius: 0, bottomRadius: 1, height: 1)
            var material = UnlitMaterial(color: .black)
            material.triangleFillMode = .lines
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let surface = {
            let mesh = MeshResource.generateCone(topRadius: 0, bottomRadius: 1, height: 1)
            let material = UnlitMaterial(color: .cyan.withAlphaComponent(0.2))
            return ModelEntity(mesh: mesh, materials: [material])
        }()
        
        let outline = {
            let mesh = MeshResource.generateCone(topRadius: 0, bottomRadius: 1, height: 1, useClockwiseTriangleWinding: true)
            let material = UnlitMaterial(color: .black)
            let model = ModelEntity(mesh: mesh, materials: [material])
            model.transform.scale = 1.0 + 0.005 * .init(1, 2, 1)
            return model
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
        
        let topRadius = intrinsics.topRadius
        let bottomRadius = intrinsics.bottomRadius
        let height = intrinsics.height
        let outlineWidth = intrinsics.outlineWidth
        let shape = intrinsics.shape
        
        if topRadius != self.intrinsics.topRadius ||
            bottomRadius != self.intrinsics.bottomRadius ||
            height != self.intrinsics.height ||
            shape != self.intrinsics.shape {
            switch intrinsics.shape {
            case .volume:
                occlusion.model?.mesh = .generateCone(topRadius: topRadius - 0.0001, bottomRadius: bottomRadius - 0.0001,
                                                      height: height - 0.0002)
                let mesh = MeshResource.generateCone(topRadius: topRadius, bottomRadius: bottomRadius, height: height)
                wireframe.model?.mesh = mesh
                surface.model?.mesh = mesh
                let diff = bottomRadius - topRadius
                let length = sqrt(height * height + diff * diff)
                let radialRatio = height / length
                let lateralRatio = diff / length
                let radiusOutline = radialRatio * outlineWidth
                let heightOutline = lateralRatio * outlineWidth
                outline.model?.mesh = .generateCone(topRadius: topRadius + radiusOutline,
                                                    bottomRadius: bottomRadius + radiusOutline,
                                                    height: height + heightOutline,
                                                    useClockwiseTriangleWinding: true)
            case .surface:
                occlusion.model?.mesh = .generateVolumetricConicalSurface(topRadius: topRadius - 0.0001,
                                                                          bottomRadius: bottomRadius - 0.0001,
                                                                          height: height,
                                                                          thickness: 0.0001)
                let mesh = MeshResource.generateConicalSurface(topRadius: topRadius, bottomRadius: bottomRadius, height: height)
                wireframe.model?.mesh = mesh
                surface.model?.mesh = mesh
                let diff = bottomRadius - topRadius
                let length = sqrt(height * height + diff * diff)
                let radialRatio = height / length
                let lateralRatio = diff / length
                let radiusOutline = radialRatio * outlineWidth
                let heightOutline = lateralRatio * outlineWidth * 2
                outline.model?.mesh = .generateVolumetricConicalSurface(topRadius: topRadius,
                                                                        bottomRadius: bottomRadius,
                                                                        height: height + heightOutline,
                                                                        thickness: radiusOutline * 2,
                                                                        useClockwiseTriangleWinding: true)
            }
        }
        
        if intrinsics.outlineWidth != self.intrinsics.outlineWidth {
            outline.transform.scale = 1.0 + outlineWidth * .init(1, 2, 1)
        }
        
        self.intrinsics = intrinsics
    }
}
