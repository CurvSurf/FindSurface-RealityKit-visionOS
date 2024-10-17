//
//  ContentView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/12/24.
//

import SwiftUI
import RealityKit
import MarkdownUI

struct ContentView: View {

    @Environment(SessionManager.self) private var sessionManager
    @Environment(AppState.self) private var state
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
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
            Text("This app uses the vertex data extracted from MeshAnchor, so it may not detect or accurately detect objects with a size (approximate diameter or width) less than 1 meter.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .frame(width: 400)
                .fixedSize(horizontal: false, vertical: true)
            
            if !sessionManager.canEnterImmersiveSpace {
                PermissionRequestView()
            }
            
            HStack {
                Button("User Guide") {
                    openWindow(sceneID: SceneID.userGuideWindow)
                }
                
                let immersiveSpaceAvailable = sessionManager.canEnterImmersiveSpace
                Button(immersiveSpaceAvailable ? "Enter" : "Not Available") {
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
                .disabled(immersiveSpaceAvailable == false)
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

fileprivate struct PermissionRequestView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @Environment(SessionManager.self) private var sessionManager
    
    var body: some View {
        VStack {
            
            Text("⚠️ Permissions Not Granted ⚠️")
                .foregroundStyle(.red)
                .padding(.top, 8)
                .padding(.bottom, 2)
            
            Text("Please tap **Go to Settings** button below to open the Settings app and enable the following permissions:")
                .font(.footnote)
                .fontWeight(.light)
                .padding(.horizontal, 30)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading) {
                
                if sessionManager.handTrackingAuthorizationStatus != .allowed {
                    Label {
                        Text("Hand Structure And Movements")
                    } icon: {
                        Image(systemName: "hand.point.up.fill")
                            .imageScale(.small)
                            .rotationEffect(.degrees(-15))
                            .padding(6)
                            .background(
                                LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .top, endPoint: .bottom)
                            )
                            .clipShape(.circle)
                            .padding(.leading, 2.1)
                            .padding(.trailing, 2)
                    }
                }
                
                if sessionManager.worldSensingAuthorizationStatus != .allowed {
                    Label {
                        Text("Surroundings")
                    } icon: {
                        Image(systemName: "camera.metering.multispot")
                            .imageScale(.small)
                            .padding(6)
                            .background(
                                LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .top, endPoint: .bottom)
                            )
                            .clipShape(.circle)
                    }
                }
            }
            
            Button("Go to Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(width: 360)
    }
}

#Preview(windowStyle: .plain) {
    ContentView()
        .environment(SessionManager())
        .environment(AppState.preview)
        .glassBackgroundEffect()
}
