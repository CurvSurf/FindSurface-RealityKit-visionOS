//
//  ContentView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/12/24.
//

import SwiftUI
import RealityKit

struct ContentView: View {

    @Environment(SessionManager.self) private var sessionManager
    @Environment(AppState.self) private var state
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack {
            Text("FindSurface for visionOS")
                .font(.title)
            
            Text("Find and measure 3D surface geometries in your physical environment.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .frame(width: 400)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)
            
            Text("PROCLAIMER")
                .font(.footnote.bold())
            Text("This app uses the vertex data extracted from MeshAnchor, so it may not detect or accurately detect objects with a size (approximate diameter) of 50 cm or less.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .frame(width: 400)
                .fixedSize(horizontal: false, vertical: true)
            
            Button("Enter") {
                Task {
                    switch await openImmersiveSpace(sceneID: SceneID.immersiveSpace) {
                    case .opened:
                        dismiss()
                    case .error:
                        await dismissImmersiveSpace()
                        state.errorCode = .openImmersiveSpaceFailed
                    case .userCancelled: break
                    @unknown default: break
                    }
                }
            }
            .padding(.top, 10)
        }
        .padding(.vertical, 24)
        .fixedSize()
        .glassBackgroundEffect()
        .onChange(of: scenePhase, initial: true) {
            if scenePhase == .active {
                Task {
                    await sessionManager.queryRequiredAuthorizations()
                }
            }
        }
        .task {
            if sessionManager.allRequiredProvidersAreSupported {
                await sessionManager.requestRequiredAuthorizations()
            }
        }
        .task {
            await sessionManager.monitorSessionEvents { error in
                state.errorCode = .sessionErrorOccurred(.init(from: error))
            }
        }
    }
}

extension AppState {
    
    @MainActor
    static var preview: AppState {
        return AppState()
    }
}

#Preview(windowStyle: .plain) {
    ContentView()
        .environment(SessionManager())
        .environment(AppState.preview)
        .glassBackgroundEffect()
}
