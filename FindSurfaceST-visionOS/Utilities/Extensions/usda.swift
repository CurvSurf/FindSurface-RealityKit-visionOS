//
//  usda.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 7/15/24.
//

import Foundation
import RealityKit
import simd

fileprivate protocol USDNode {
    func description(path: String) -> String
}

extension Array: USDNode where Element == (any USDNode) {
    func description(path: String) -> String {
        return map { $0.description(path: path) }.joined(separator: "\n\n")
    }
}

@resultBuilder fileprivate struct USDBuilder {
    static func buildArray(_ components: [any USDNode]) -> any USDNode {
        components
    }
    static func buildBlock(_ components: USDNode...) -> USDNode {
        return components
    }
    static func buildEither(first component: any USDNode) -> any USDNode {
        return component
    }
    static func buildEither(second component: any USDNode) -> any USDNode {
        return component
    }
}

fileprivate enum Axis: String {
    case x = "X"
    case y = "Y"
    case z = "Z"
}

fileprivate struct USDDocument {
    
    let name: String
    let creator: String
    let metersPerUnit: Float
    let upAxis: Axis
    @USDBuilder let content: () -> any USDNode
    
    init(name: String, creator: String = "unknown", metersPerUnit: Float = 1, upAxis: Axis = .y, @USDBuilder content: @escaping () -> any USDNode) {
        self.name = name
        self.creator = creator
        self.metersPerUnit = metersPerUnit
        self.upAxis = upAxis
        self.content = content
    }
    
    func description() -> String {
        return """
#usda 1.0
(
    customLayerData = {
        string creator = "\(creator)"
    }
    defaultPrim = "\(name)"
    metersPerUnit = \(metersPerUnit)
    upAxis = "\(upAxis.rawValue)"
)

def Xform "\(name)" {

\(content().description(path: name), indent: 1)
}
"""
    }
}

fileprivate struct USDScope: USDNode {
    
    let name: String
    @USDBuilder let content: () -> any USDNode
    
    func description(path: String) -> String {
        return """
def Scope "\(name)" {

\(content().description(path: path + "/\(name)"), indent: 1)
}
"""
    }
}

fileprivate struct USDMaterial: USDNode {
    
    let name: String
    let color: simd_float3
    let opacity: Float
    let roughness: Float
    
    init(name: String, color: simd_float3, opacity: Float, roughness: Float = 0.75) {
        self.name = name
        self.color = color
        self.opacity = opacity
        self.roughness = roughness
    }
    
    func description(path: String) -> String {
        return """
def Material "\(name)" {
    prepend token outputs:surface.connect = </\(path)/\(name)/DefaultSurfaceShader.outputs:surface>

    def Shader "DefaultSurfaceShader" {
        uniform token info:id = "UsdPreviewSurface"
        color3f inputs:diffuseColor = \(usd: color, .color)
        float inputs:opacity = \(usd: opacity, .opacity)
        float inputs:roughness = \(usd: roughness, .roughness)
        token outputs:surface
    }
}
"""
    }
}

fileprivate struct USDPlaneMesh: USDNode {
    
    let name: String
    
    func description(path: String) -> String {
        return """
def Mesh "\(name)" {
    int[] faceVertexCounts = [4, 4]
    int[] faceVertexIndices = [0, 1, 2, 3, 7, 6, 5, 4]
    normal3f[] normals = [(0, 0, 1), (0, 0, -1)] ( interpolation = "uniform" )
    point3f[] points = [(-0.5, -0.5, 0.00005), (0.5, -0.5, 0.00005), (0.5, 0.5, 0.00005), (-0.5, 0.5, 0.00005), (-0.5, -0.5, -0.00005), (0.5, -0.5, -0.00005), (0.5, 0.5, -0.00005), (-0.5, 0.5, -0.00005)]
    uniform token subdivisionScheme = "none"
}
"""
    }
}

fileprivate enum Interpolation: String {
    case constant = "constant"
    case uniform = "uniform"
    case varying = "varying"
    case vertex = "vertex"
    case faceVarying = "faceVarying"
}

fileprivate struct USDMesh: USDNode {
    
    let name: String
    let faceVertexCounts: [Int]
    let faceVertexIndices: [Int]
    let points: [simd_float3]
    let primvars_normals: [simd_float3]
    let primvars_normals_indices: [Int]
    let primvars_normals_interpolation: Interpolation
    
    func description(path: String) -> String {
        return """
def Mesh "\(name)" {
    int[] faceVertexCounts = [\(faceVertexCounts.map { "\($0)" }.joined(separator: ", "))]
    int[] faceVertexIndices = [\(faceVertexIndices.map { "\($0)" }.joined(separator: ", "))]
    point3f[] points = [\(points.map { "\(usd: $0)" }.joined(separator: ", "))]
    normal3f[] primvars:normals = [\(primvars_normals.map { "\(usd: $0) "}.joined(separator: ", "))] ( interpolation = "\(primvars_normals_interpolation.rawValue)" )
    int[] primvars:normals:indices = [\(primvars_normals_indices.map { "\($0)" }.joined(separator: ", "))]
    uniform token subdivisionScheme = "none"
}
"""
    }
}

fileprivate struct USDCustomDataField {
    let type: String
    let varname: String
    let value: String
    
    func description() -> String {
        return "\(type) \(varname) = \(value)"
    }
}

extension USDCustomDataField {
    init(varname: String, value: Float) {
        self.init(type: "float", varname: varname, value: "\(usd: value)")
    }
    init(varname: String, value: simd_float3) {
        self.init(type: "float3", varname: varname, value: "\(usd: value)")
    }
}

fileprivate struct USDMetadata {
    let customData: [USDCustomDataField]
    let instanceable: Bool
    let specifyApiSchemas: Bool
    
    init(customData: [USDCustomDataField] = [],
         instanceable: Bool = false,
         specifyApiSchemas: Bool = false) {
        self.customData = customData
        self.instanceable = instanceable
        self.specifyApiSchemas = specifyApiSchemas
    }
    
    func description() -> String {
        let customDataStr = if customData.isEmpty {
            """
            
            """
        } else {
            """
            customData = {
            \(customData.map { $0.description() }.joined(separator: "\n"), indent: 1)
            }
            """
        }
        let instanceableStr = if instanceable {
            """
            
            instanceable = true
            """
        } else {
            ""
        }
        let apiSchemasStr = if specifyApiSchemas {
            """
            
            prepend apiSchemas = ["MaterialBindingAPI"]
            """
        } else {
            ""
        }
        return """
        \(customDataStr)\(instanceableStr)\(apiSchemasStr)
        """
    }
}

fileprivate struct USDTransform: USDNode {
    let orient: simd_quatf
    let scale: simd_float3
    let translate: simd_float3
    
    init(orient: simd_quatf = .init(),
         scale: simd_float3 = .one,
         translate: simd_float3 = .zero) {
        self.orient = orient
        self.scale = scale
        self.translate = translate
    }
    
    func description(path: String) -> String {
        return """
        quatf xformOp:orient = \(usd: orient)
        float3 xformOp:scale = \(usd: scale)
        float3 xformOp:translate = \(usd: translate)
        uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:orient", "xformOp:scale"]
        """
    }
}

fileprivate struct USDXForm: USDNode {
    
    let name: String
    let metadata: USDMetadata?
    @USDBuilder let content: () -> any USDNode
    
    init(name: String,
         metadata: USDMetadata? = nil,
         @USDBuilder content: @escaping () -> any USDNode) {
        self.name = name
        self.metadata = metadata
        self.content = content
    }
    
    func description(path: String) -> String {
        
        let metadataStr = if let metadata {
            """
            (
            
            \(metadata.description(), indent: 1)
            ) {
            """
        } else {
            "{"
        }
        return """
        def Xform "\(name)" \(metadataStr)
        
        \(content().description(path: path + "/\(name)"), indent: 1)
        }
        """
    }
}

fileprivate struct USDRef: USDNode {
    
    let name: String
    let ref: String
    
    func description(path: String) -> String {
        return """
        def Xform "\(name)" (references = </\(ref)>) {}
        """
    }
}

fileprivate struct USDMaterialBinding: USDNode {
    
    let materialPath: String
    
    func description(path: String) -> String {
        return """
        rel material:binding = </\(materialPath)>
        """
    }
}

fileprivate struct USDEmptyNode: USDNode {
    
    func description(path: String) -> String {
        ""
    }
}

fileprivate protocol USDAExportable {
    func export() -> USDXForm
}

fileprivate let documentName = "FindSurfaceResults"
fileprivate let creatorName = "FindSurfaceST-visionOS"
fileprivate let materialScopeName = "Materials"
fileprivate let meshScopeName = "Meshes"

fileprivate let planeMaterialName = "Plane"
fileprivate let sphereMaterialName = "Sphere"
fileprivate let cylinderMaterialName = "Cylinder"
fileprivate let coneMaterialName = "Cone"
fileprivate let torusMaterialName = "Torus"

fileprivate let planeMaterialBindingPath = "\(documentName)/\(materialScopeName)/\(planeMaterialName)"
fileprivate let sphereMaterialBindingPath = "\(documentName)/\(materialScopeName)/\(sphereMaterialName)"
fileprivate let cylinderMaterialBindingPath = "\(documentName)/\(materialScopeName)/\(cylinderMaterialName)"
fileprivate let coneMaterialBindingPath = "\(documentName)/\(materialScopeName)/\(coneMaterialName)"
fileprivate let torusMaterialBindingPath = "\(documentName)/\(materialScopeName)/\(torusMaterialName)"

fileprivate let planeMeshName = "Plane"
fileprivate let sphereMeshName = "Sphere"
fileprivate let cylinderMeshName = "Cylinder"

fileprivate let planeMeshRef = "\(documentName)/\(meshScopeName)/\(planeMeshName)"
fileprivate let sphereMeshRef = "\(documentName)/\(meshScopeName)/\(sphereMeshName)"
fileprivate let cylinderMeshRef = "\(documentName)/\(meshScopeName)/\(cylinderMeshName)"

fileprivate extension Submesh {
    
    var faceVertexCounts: [Int] {
        [Int](repeating: 3, count: triangleIndices.chunks(ofCount: 3).count)
    }
    
    var faceVertexIndices: [Int] {
        triangleIndices.map { Int($0) }
    }
    
    var points: [simd_float3] {
        positions
    }
    
    var primvars_normals: [simd_float3] {
        normals
    }
    
    var primvars_normals_indices: [Int] {
        faceVertexIndices
    }
    
}

fileprivate extension USDMesh {
    static func create(name: String, submesh: Submesh) -> USDMesh {
        let faceVertexCounts = [Int](repeating: 3, count: submesh.triangleIndices.count / 3)
        let faceVertexIndices = submesh.triangleIndices.map { Int($0) }
        let points = submesh.positions
        let primvars_normals = submesh.normals
        let primvars_normals_indices = faceVertexIndices
        let primvars_normals_interpolation = Interpolation.faceVarying
        return USDMesh(name: name,
                       faceVertexCounts: faceVertexCounts,
                       faceVertexIndices: faceVertexIndices,
                       points: points,
                       primvars_normals: primvars_normals,
                       primvars_normals_indices: primvars_normals_indices,
                       primvars_normals_interpolation: primvars_normals_interpolation)
    }
}

@MainActor
func export(_ geometries: [GeometryEntity]) -> String {
    
    let document = USDDocument(name: documentName, creator: creatorName) {
        
        USDScope(name: materialScopeName) {
            
            USDMaterial(name: planeMaterialName, color: .init(1, 0, 0), opacity: 0.5)
            USDMaterial(name: sphereMaterialName, color: .init(0, 1, 0), opacity: 0.5)
            USDMaterial(name: cylinderMaterialName, color: .init(1, 0, 1), opacity: 0.5)
            USDMaterial(name: coneMaterialName, color: .init(0, 1, 1), opacity: 0.5)
            USDMaterial(name: torusMaterialName, color: .init(1, 1, 0), opacity: 0.5)
        }
        
        USDXForm(name: meshScopeName) {
            
            USDTransform(scale: .init(repeating: 0.0000001))
            
            USDXForm(name: planeMeshName) {
                USDPlaneMesh(name: "\(planeMeshName)Mesh")
            }
            
            USDXForm(name: sphereMeshName) {
                USDMesh.create(name: "\(sphereMeshName)Mesh", submesh: .generateLowPolySphere(radius: 1.0))
            }
            
            USDXForm(name: cylinderMeshName) {
                USDMesh.create(name: "\(cylinderMeshName)Mesh", submesh: .generateCylindricalSurface(radius: 1, height: 1))
            }
        }
        
        for geometry in geometries {
            switch geometry {
            case let plane as PlaneEntity:          plane.export()
            case let sphere as SphereEntity:        sphere.export()
            case let cylinder as CylinderEntity:    cylinder.export()
            case let cone as ConeEntity:            cone.export()
            case let torus as TorusEntity:          torus.export()
            default:                                USDEmptyNode()
            }
        }
    }
    
    return document.description()
}

extension PlaneEntity: USDAExportable {
    fileprivate func export() -> USDXForm {
        let width = intrinsics.width
        let height = intrinsics.height
        let center = position
        let horizontal = transform.matrix.basisX
        let vertical = transform.matrix.basisY
        let normal = transform.matrix.basisZ
        let orient = transform.rotation
        
        let metadata = USDMetadata(customData: [
            USDCustomDataField(varname: "width", value: width),
            USDCustomDataField(varname: "height", value: height),
            USDCustomDataField(varname: "center", value: center),
            USDCustomDataField(varname: "horizontal", value: horizontal),
            USDCustomDataField(varname: "vertical", value: vertical),
            USDCustomDataField(varname: "normal", value: normal)
        ], instanceable: true, specifyApiSchemas: true)
        
        return USDXForm(name: name, metadata: metadata) {
            USDRef(name: "PlaneRef", ref: planeMeshRef)
            USDMaterialBinding(materialPath: planeMaterialBindingPath)
            USDTransform(orient: orient,
                         scale: .init(width, height, 1),
                         translate: center)
        }
    }
}

extension SphereEntity: USDAExportable {
    fileprivate func export() -> USDXForm {
        let radius = intrinsics.radius
        let center = position
        
        let metadata = USDMetadata(customData: [
            USDCustomDataField(varname: "radius", value: radius),
            USDCustomDataField(varname: "center", value: center)
        ], instanceable: true, specifyApiSchemas: true)
        
        return USDXForm(name: name, metadata: metadata) {
            USDRef(name: "SphereRef", ref: sphereMeshRef)
            USDMaterialBinding(materialPath: sphereMaterialBindingPath)
            USDTransform(scale: .one * radius, translate: center)
        }
    }
}

extension CylinderEntity: USDAExportable {
    fileprivate func export() -> USDXForm {
        let radius = intrinsics.radius
        let height = intrinsics.height
        let center = position
        let axis = transform.matrix.basisY
        let orient = transform.rotation
        
        let metadata = USDMetadata(customData: [
            USDCustomDataField(varname: "radius", value: radius),
            USDCustomDataField(varname: "height", value: height),
            USDCustomDataField(varname: "center", value: center),
            USDCustomDataField(varname: "axis", value: axis)
        ], instanceable: true, specifyApiSchemas: true)
        
        return USDXForm(name: name, metadata: metadata) {
            USDRef(name: "CylinderRef", ref: cylinderMeshRef)
            USDMaterialBinding(materialPath: cylinderMaterialBindingPath)
            USDTransform(orient: orient, scale: .init(radius, height, radius), translate: center)
        }
    }
}

extension ConeEntity: USDAExportable {
    fileprivate func export() -> USDXForm {
        let topRadius = intrinsics.topRadius
        let bottomRadius = intrinsics.bottomRadius
        let height = intrinsics.height
        let center = position
        let axis = transform.matrix.basisY
        let orient = transform.rotation
        
        let metadata = USDMetadata(customData: [
            USDCustomDataField(varname: "topRadius", value: topRadius),
            USDCustomDataField(varname: "bottomRadius", value: bottomRadius),
            USDCustomDataField(varname: "height", value: height),
            USDCustomDataField(varname: "center", value: center),
            USDCustomDataField(varname: "axis", value: axis)
        ], instanceable: true, specifyApiSchemas: true)
        
        return USDXForm(name: name, metadata: metadata) {
            
            USDMesh.create(name: "ConeMesh", submesh: .generateConicalSurface(topRadius: topRadius,
                                                                              bottomRadius: bottomRadius,
                                                                              height: height))
            USDMaterialBinding(materialPath: coneMaterialBindingPath)
            USDTransform(orient: orient, translate: center)
        }
    }
}

import SwiftUI

extension TorusEntity: USDAExportable {
    fileprivate func export() -> USDXForm {
        let meanRadius = intrinsics.meanRadius
        let tubeRadius = intrinsics.tubeRadius
        let center = position
        let axis = transform.matrix.basisY
        let (beginAngle, tubeAngle): (Angle, Angle) = switch intrinsics.shape {
        case .fullVolume:                        (Angle(degrees: 0), Angle(degrees: 360))
        case let .partialSurface(beginAngle, deltaAngle): (beginAngle, deltaAngle)
        case let .partialVolume(beginAngle, deltaAngle):  (beginAngle, deltaAngle)
        }
        let orient = transform.rotation
        
        let metadata = USDMetadata(customData: [
            USDCustomDataField(varname: "meanRadius", value: meanRadius),
            USDCustomDataField(varname: "tubeRadius", value: tubeRadius),
            USDCustomDataField(varname: "center", value: center),
            USDCustomDataField(varname: "axis", value: axis),
            USDCustomDataField(varname: "tubeAngle", value: Float(tubeAngle.radians))
        ], instanceable: true, specifyApiSchemas: true)
        
        return USDXForm(name: name, metadata: metadata) {
            let deltaAngle = tubeAngle.radians < 0 ? -tubeAngle : tubeAngle
            let toricSurface = if deltaAngle.degrees > 270 {
                Submesh.generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius)
            } else {
                rotatedSubmesh(meanRadius: meanRadius, tubeRadius: tubeRadius, beginAngle: beginAngle, tubeAngle: deltaAngle)
            }
            
            USDMesh.create(name: "TorusMesh", submesh: toricSurface)
            
            USDMaterialBinding(materialPath: torusMaterialBindingPath)
            USDTransform(orient: orient, translate: center)
        }
    }
}

fileprivate func rotatedSubmesh(meanRadius: Float, tubeRadius: Float, beginAngle: Angle, tubeAngle: Angle) -> Submesh {
    
    var submesh = Submesh.generateToricSurface(meanRadius: meanRadius, tubeRadius: tubeRadius, angle: tubeAngle)
    let beginCircleDirection = simd_float3(cos(Float(beginAngle.radians)), 0, sin(Float(beginAngle.radians)))
    let rotation = simd_quatf(from: .init(1, 0, 0), to: beginCircleDirection)
    if rotation.angle != 0 {
        submesh.positions = submesh.positions.map { rotation.act($0) }
        submesh.normals = submesh.normals.map { rotation.act($0) }
    }
    return submesh
}

fileprivate enum Digits {
    case length
    case color
    case opacity
    case roughness
    
    var rawValue: Int {
        switch self {
        case .length: return 8
        case .color: return 4
        case .opacity, .roughness: return 2
        }
    }
}

fileprivate extension String.StringInterpolation {
    
    mutating func appendInterpolation(usd scalar: Float, digits: Int = 8) {
        appendLiteral(String(format: "%.\(digits)f", scalar))
    }
    
    mutating func appendInterpolation(usd scalar: Float, _ digits: Digits) {
        appendInterpolation(usd: scalar, digits: digits.rawValue)
    }
    
    mutating func appendInterpolation(usd vector: simd_float3, digits: Int = 8) {
        let x = "\(usd: vector.x, digits: digits)"
        let y = "\(usd: vector.y, digits: digits)"
        let z = "\(usd: vector.z, digits: digits)"
        appendLiteral("(\(x), \(y), \(z))")
    }
    
    mutating func appendInterpolation(usd vector: simd_float3, _ digits: Digits) {
        appendInterpolation(usd: vector, digits: digits.rawValue)
    }
    
    mutating func appendInterpolation(usd quaternion: simd_quatf, digits: Int = 8) {
        let w = "\(usd: quaternion.real, digits: digits)"
        let x = "\(usd: quaternion.imag.x, digits: digits)"
        let y = "\(usd: quaternion.imag.y, digits: digits)"
        let z = "\(usd: quaternion.imag.z, digits: digits)"
        appendLiteral("(\(w), \(x), \(y), \(z))")
    }
    
    mutating func appendInterpolation(usd quaternion: simd_quatf, _ digits: Digits) {
        appendInterpolation(usd: quaternion, digits: digits.rawValue)
    }
    
    mutating func appendInterpolation(repeating token: String, count: Int) {
        appendLiteral(String(repeating: token, count: count))
    }
    
    mutating func appendInterpolation(_ content: String, indent: Int) {
        let result = content.split(separator: "\n", omittingEmptySubsequences: false).map { line in
            "\(repeating: "\t", count: indent)\(line)"
        }.joined(separator: "\n")
        appendLiteral(result)
    }
}
