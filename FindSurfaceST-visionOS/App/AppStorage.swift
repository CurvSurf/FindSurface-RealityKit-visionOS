//
//  AppStorage.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation

import FindSurface_visionOS

fileprivate extension String {
    static var measurementAccuracy: String { "measurement-accuracy" }
    static var meanDistance: String { "mean-distance" }
    static var seedRadius: String { "seed-radius" }
    static var lateralExtension: String { "lateral-extension" }
    static var radialExpansion: String { "radial-expansion" }
    static var allowsConeToCylinderConversion: String { "allows-cone-to-cylinder-conversion" }
    static var allowsTorusToSphereConversion: String { "allows-torus-to-sphere-conversion" }
    static var allowsTorusToCylinderConversion: String { "allows-torus-to-cylinder-conversion" }
    
    static var showInlierPoints: String { "show-inlier-points" }
    static var showResultPanel: String { "show-result-panel" }
    static var showGeometryOutline: String { "show-geometry-outline" }
}

extension AppState {
    
    @MainActor 
    func loadFromAppStorage() {
        let storage = UserDefaults.standard
        showInlierPoints = storage.boolValue(forKey: .showInlierPoints) ?? true
        showResultPanel = storage.boolValue(forKey: .showResultPanel) ?? true
        showGeometryOutline = storage.boolValue(forKey: .showGeometryOutline) ?? true
    }
    
    @MainActor 
    func saveToAppStorage() {
        let storage = UserDefaults.standard
        storage.set(showInlierPoints, forKey: .showInlierPoints)
        storage.set(showResultPanel, forKey: .showResultPanel)
        storage.set(showGeometryOutline, forKey: .showGeometryOutline)
    }
}

extension FindSurface {
    
    func loadFromAppStorage() {
        let storage = UserDefaults.standard
        measurementAccuracy = storage.floatValue(forKey: .measurementAccuracy) ?? 0.015
        meanDistance = storage.floatValue(forKey: .meanDistance) ?? 0.10
        seedRadius = storage.floatValue(forKey: .seedRadius) ?? 0.15
        lateralExtension = storage.enumValue(forKey: .lateralExtension) ?? .lv10
        radialExpansion = storage.enumValue(forKey: .radialExpansion) ?? .lv5
        var options = ConversionOptions()
        if storage.boolValue(forKey: .allowsConeToCylinderConversion) ?? true {
            options.insert(.coneToCylinder)
        }
        if storage.boolValue(forKey: .allowsTorusToSphereConversion) ?? true {
            options.insert(.torusToSphere)
        }
        if storage.boolValue(forKey: .allowsTorusToCylinderConversion) ?? true {
            options.insert(.torusToCylinder)
        }
        conversionOptions = options
    }
    
    func saveToAppStorage() {
        let storage = UserDefaults.standard
        storage.set(measurementAccuracy, forKey: .measurementAccuracy)
        storage.set(meanDistance, forKey: .meanDistance)
        storage.set(seedRadius, forKey: .seedRadius)
        storage.set(lateralExtension, forKey: .lateralExtension)
        storage.set(radialExpansion, forKey: .radialExpansion)
        storage.set(conversionOptions.contains(.coneToCylinder), forKey: .allowsConeToCylinderConversion)
        storage.set(conversionOptions.contains(.torusToSphere), forKey: .allowsTorusToSphereConversion)
        storage.set(conversionOptions.contains(.torusToCylinder), forKey: .allowsTorusToCylinderConversion)
    }
}

extension UserDefaults {
    
    func boolValue(forKey key: String) -> Bool? {
        return object(forKey: key) as? Bool
    }
    
    func intValue(forKey key: String) -> Int? {
        return object(forKey: key) as? Int
    }
    
    func doubleValue(forKey key: String) -> Double? {
        return object(forKey: key) as? Double
    }
    
    func floatValue(forKey key: String) -> Float? {
        guard let value = doubleValue(forKey: key) else { return nil }
        return Float(value)
    }
    
    func enumValue<T>(forKey key: String) -> T? where T: RawRepresentable, T.RawValue == Int {
        guard let rawValue = intValue(forKey: key),
              let value = T(rawValue: rawValue) else {
            return nil
        }
        return value
    }
    
    func enumValue<T>(forKey key: String) -> T? where T: RawRepresentable, T.RawValue == String {
        guard let rawValue = string(forKey: key),
              let value = T(rawValue: rawValue) else {
            return nil
        }
        return value
    }
    
    func set(_ value: Float, forKey key: String) {
        set(Double(value), forKey: key)
    }
    
    func set<T>(_ value: T, forKey key: String) where T: RawRepresentable, T.RawValue == Int {
        set(value.rawValue, forKey: key)
    }
    
    func set<T>(_ value: T, forKey key: String) where T: RawRepresentable, T.RawValue == String {
        set(value.rawValue, forKey: key)
    }
}
