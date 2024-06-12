//
//  TrackingScenePhaseModifier.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import SwiftUI

struct TrackingScenePhaseModifier<Tracker: ScenePhaseTrackerProtocol>: ViewModifier {
    
    let sceneID: Tracker.SceneID
    let tracker: Tracker
    
    @Environment(\.scenePhase) private var scenePhase
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                tracker.activeScene.insert(sceneID)
            }
            .onDisappear {
                tracker.activeScene.remove(sceneID)
            }
            .onChange(of: scenePhase, initial: true) { _, newPhase in
                if newPhase == .active {
                    tracker.activeScene.insert(sceneID)
                } else {
                    tracker.activeScene.remove(sceneID)
                }
            }
    }
}

extension View {
    func trackingScenePhase<Tracker: ScenePhaseTrackerProtocol>(by tracker: Tracker, sceneID: Tracker.SceneID) -> some View {
        modifier(TrackingScenePhaseModifier(sceneID: sceneID, tracker: tracker))
    }
}
