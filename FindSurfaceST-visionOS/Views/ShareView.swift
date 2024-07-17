//
//  ShareView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 7/17/24.
//

import Foundation
import SwiftUI

struct ShareView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    @Environment(ScenePhaseTracker.self) private var scenePhaseTracker
    let url: URL
    
    var body: some View {
        _ShareView(url: url)
            .onChange(of: scenePhase) {
                if scenePhase == .inactive &&
                    !scenePhaseTracker.activeScene.contains(.immersiveSpace) &&
                    !scenePhaseTracker.activeScene.contains(.mainWindow) {
                    openWindow(sceneID: SceneID.mainWindow)
                }
            }
    }
}

struct _ShareView: UIViewControllerRepresentable {
    
    @Environment(\.dismiss) private var dismiss
    
    let url: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let viewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        viewController.excludedActivityTypes = [
            .message,
            .mail,
        ]
        viewController.completionWithItemsHandler = { activity, success, items, error in
            if !success {
                dismiss()
            }
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        
    }
}
