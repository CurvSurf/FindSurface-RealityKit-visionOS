//
//  FindSurfaceST_visionOSApp.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/12/24.
//

import SwiftUI

import FindSurface_visionOS

enum SceneID: String, SceneIDProtocol {
    case mainWindow = "Main Window"
    case immersiveSpace = "Immersive Space"
    case errorWindow = "Error Window"
    case userGuideWindow = "User Guide Window"
    case shareWindow = "Share Window"
}

@Observable
final class ScenePhaseTracker: ScenePhaseTrackerProtocol {
    var activeScene: Set<SceneID> = []
}

fileprivate extension Set where Element: CaseIterable {
    func containsOnly(_ element: Element) -> Bool {
        return self == [element]
    }
}

@MainActor
@main
struct FindSurfaceST_visionOSApp: App {
    
    @Environment(\.openWindow) private var openWindow
    
    @State private var sessionManager = SessionManager()
    @State private var appState = AppState()
    @State private var findSurface = FindSurface.instance
    @State private var scenePhaseTracker = ScenePhaseTracker()
    
    var body: some Scene {
        WindowGroup(sceneID: SceneID.mainWindow) {
            ContentView()
                .task {
                    PersistentComponent.registerComponent()
                }
                .environment(sessionManager)
                .environment(appState)
                .trackingScenePhase(by: scenePhaseTracker, sceneID: .mainWindow)
                .onChange(of: appState.errorCode) { _, errorCode in
                    guard let errorCode,
                          scenePhaseTracker.activeScene.containsOnly(.mainWindow) else { return }
                    openWindow(sceneID: SceneID.errorWindow, value: errorCode)
                }
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)

        ImmersiveSpace(sceneID: SceneID.immersiveSpace) {
            ImmersiveView()
                .environment(appState)
                .environment(sessionManager)
                .environment(findSurface)
                .environment(scenePhaseTracker)
                .trackingScenePhase(by: scenePhaseTracker, sceneID: .immersiveSpace)
                .onChange(of: appState.errorCode) { _, errorCode in
                    guard let errorCode,
                          scenePhaseTracker.activeScene.containsOnly(.immersiveSpace) else { return }
                    openWindow(sceneID: SceneID.errorWindow, value: errorCode)
                }
        }
        
        WindowGroup(sceneID: SceneID.errorWindow, for: ErrorCode.self) { errorCode in
            if let errorCode = errorCode.wrappedValue {
                ErrorView(errorCode: errorCode)
                    .trackingScenePhase(by: scenePhaseTracker, sceneID: .errorWindow)
                    .glassBackgroundEffect()
            }
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        
        WindowGroup(sceneID: SceneID.userGuideWindow) {
            UserGuideView()
                .environment(scenePhaseTracker)
                .trackingScenePhase(by: scenePhaseTracker, sceneID: .userGuideWindow)
                .glassBackgroundEffect()
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        
        WindowGroup(sceneID: SceneID.shareWindow, for: URL.self) { url in
            if let url = url.wrappedValue {
                ShareView(url: url)
                    .environment(scenePhaseTracker)
                    .trackingScenePhase(by: scenePhaseTracker, sceneID: .shareWindow)
                    .frame(width: 600, height: 420)
                    .glassBackgroundEffect()
            }
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
    }
}
