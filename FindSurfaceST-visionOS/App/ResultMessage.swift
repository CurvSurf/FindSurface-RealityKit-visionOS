//
//  ResultMessage.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation

struct ResultMessage: Equatable {
    let uuid = UUID()
    let message: String
    init(_ message: String) {
        self.message = message
    }
}

extension ResultMessage {
    init(from object: PersistentObject) {
        self.init(object.message)
    }
}

fileprivate extension PersistentObject {
    var message: String {
        switch self {
        case let .plane(name, plane, _, rmsError):
            return "\(name): \(length: plane.width), \(length: plane.height), \(position: plane.center), \(direction: plane.normal), \(length: rmsError)"
        case let .sphere(name, sphere, _, rmsError):
            return "\(name): \(length: sphere.radius), \(position: sphere.center), \(length: rmsError)"
        case let .cylinder(name, cylinder, _, rmsError):
            return "\(name): \(length: cylinder.radius), \(length: cylinder.height), \(position: cylinder.center), \(direction: cylinder.axis), \(length: rmsError)"
        case let .cone(name, cone, _, rmsError):
            return "\(name): \(length: cone.topRadius), \(length: cone.bottomRadius), \(length: cone.height), \(position: cone.center), \(direction: cone.axis), \(length: rmsError)"
        case let .torus(name, torus, inliers, rmsError):
            let (_, delta) = torus.calcAngleRange(from: inliers)
            let deltaAngle = delta >= .radians(fromDegrees: 270) ? .twoPi : delta
            let angleText = String(format: "%.1f", Float.degrees(fromRadians: deltaAngle))
            return "\(name): \(length: torus.meanRadius), \(length: torus.tubeRadius), \(position: torus.center), \(direction: torus.axis), \(angleText), \(length: rmsError)"
        }
    }
}
