//
//  PersistentObject.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import simd
import RealityKit

import FindSurface_visionOS

struct PersistentDataHolder {
    
    fileprivate enum ObjectType {
        case plane, sphere, cylinder, cone, torus
    }
    
    var name: String
    fileprivate var type: ObjectType
    var object: any GeometryObject
    var inliers: [simd_float3]
    var rmsError: Float
    
    fileprivate init(_ name: String,
         _ type: ObjectType,
         _ object: any GeometryObject,
         _ inliers: [simd_float3],
         _ rmsError: Float) {
        self.name = name
        self.type = type
        self.object = object
        self.inliers = inliers
        self.rmsError = rmsError
    }
}

@dynamicMemberLookup
enum PersistentObject: Hashable, Codable {

    case plane(String, Plane, [simd_float3], Float)
    case sphere(String, Sphere, [simd_float3], Float)
    case cylinder(String, Cylinder, [simd_float3], Float)
    case cone(String, Cone, [simd_float3], Float)
    case torus(String, Torus, [simd_float3], Float)
    
    subscript<T>(dynamicMember keyPath: WritableKeyPath<PersistentDataHolder, T>) -> T {
        get {
            return PersistentDataHolder(from: self)[keyPath: keyPath]
        }
        set {
            var object = PersistentDataHolder(from: self)
            object[keyPath: keyPath] = newValue
            self = object.asObject()
        }
    }
}

extension PersistentDataHolder {
    fileprivate init(from object: PersistentObject) {
        switch object {
        case let .plane(name, object, inliers, rmsError):
            self.init(name, .plane, object, inliers, rmsError)
        case let .sphere(name, object, inliers, rmsError):
            self.init(name, .sphere, object, inliers, rmsError)
        case let .cylinder(name, object, inliers, rmsError):
            self.init(name, .cylinder, object, inliers, rmsError)
        case let .cone(name, object, inliers, rmsError):
            self.init(name, .cone, object, inliers, rmsError)
        case let .torus(name, object, inliers, rmsError):
            self.init(name, .torus, object, inliers, rmsError)
        }
    }
    
    fileprivate func asObject() -> PersistentObject {
        switch type {
        case .plane:    return .plane(name, object as! Plane, inliers, rmsError)
        case .sphere:   return .sphere(name, object as! Sphere, inliers, rmsError)
        case .cylinder: return .cylinder(name, object as! Cylinder, inliers, rmsError)
        case .cone:     return .cone(name, object as! Cone, inliers, rmsError)
        case .torus:    return .torus(name, object as! Torus, inliers, rmsError)
        }
    }
}

final class PersistentComponent: Component {
    var object: PersistentObject
    
    init(object: PersistentObject) {
        self.object = object
    }
}

fileprivate let objectsDatabaseFilename = "fs-persistentObjects.json"

extension Dictionary where Key == UUID, Value == PersistentObject {
    
    static func load() throws -> Self {
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsDirectory.appendingPathComponent(objectsDatabaseFilename)
        
        var directoryWithSameNameExists: ObjCBool = false
        if FileManager.default.fileExists(atPath: filePath.path(percentEncoded: true), isDirectory: &directoryWithSameNameExists) == false {
            guard directoryWithSameNameExists.boolValue == false else {
                throw ErrorCode.fileLoadFailed
            }
            try [:].save()
        }
        
        do {
            let data = try Data(contentsOf: filePath)
            return try JSONDecoder().decode([UUID: PersistentObject].self, from: data)
        } catch {
            throw ErrorCode.saveFileCorrupted("\(error)")
        }
    }
    
    func save() throws {
        let encoder = JSONEncoder()
        do {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filePath = documentsDirectory.appendingPathComponent(objectsDatabaseFilename)
            try encoder.encode(self).write(to: filePath)
        } catch {
            throw ErrorCode.fileSaveFailed("\(error)")
        }
    }
}
