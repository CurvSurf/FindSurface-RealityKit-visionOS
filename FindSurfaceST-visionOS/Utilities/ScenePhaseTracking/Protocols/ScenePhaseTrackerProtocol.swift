//
//  ScenePhaseTrackerProtocol.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation

protocol ScenePhaseTrackerProtocol: AnyObject {
    
    associatedtype SceneID: SceneIDProtocol
    
    var activeScene: Set<SceneID> { get set }
}
