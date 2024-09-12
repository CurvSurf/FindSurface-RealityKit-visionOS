//
//  UserGuideView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 7/1/24.
//

import Foundation
import SwiftUI

import MarkdownUI

fileprivate struct LoadingView: View {
    var body: some View {
        ProgressView {
            Text("Loading...")
        }
        .padding()
        .frame(width: 150, height: 100)
    }
}

fileprivate struct LoadingFailedView: View {
    var body: some View {
        VStack {
            Text("Couldn't load the content.")
                .font(.title2)
            
            if let url = URL(string: "https://github.com/CurvSurf/FindSurface-RealityKit-visionOS/blob/main/README.md#how-to-use") {
                Text("Refer to the website below instead.")
                Link(destination: url) {
                    Text("Open in Safari Browser")
                }
            }
        }
        .padding()
        .frame(width: 350, height: 140)
    }
}

struct UserGuideView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    @Environment(ScenePhaseTracker.self) private var scenePhaseTracker
    @State private var content: String? = nil
    @State private var isLoading: Bool = true
    
    var body: some View {
        ZStack {
            if isLoading {
                LoadingView()
            } else if let content {
                ScrollView {
                    Markdown(content)
                        .markdownImageProvider(.resource)
                        .padding()
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(width: 700, height: 600)
            } else {
                LoadingFailedView()
            }
        }
        .task {
            isLoading = true
            await loadContent()
            isLoading = false
        }
        .onChange(of: scenePhase) {
            if scenePhase == .inactive &&
                !scenePhaseTracker.activeScene.contains(.immersiveSpace) &&
                !scenePhaseTracker.activeScene.contains(.mainWindow) {
                openWindow(sceneID: SceneID.mainWindow)
            }
        }
    }
    
    @MainActor
    private func loadContent() async {
        
        guard content == nil,
              let url = Bundle.main.url(forResource: "README", withExtension: "md"),
              let data = try? Data(contentsOf: url) else { return }
        content = String(data: data, encoding: .utf8)
        isLoading = false
    }
}

fileprivate struct ResourceImageProvider: ImageProvider {
    
    @ViewBuilder func makeImage(url: URL?) -> some View {
        if let url {
            let fileName = url.deletingPathExtension().lastPathComponent
            let fileExtension = url.pathExtension
            let filePath = url.deletingLastPathComponent().relativeString
            if let imageURL = Bundle.main.url(forResource: fileName,
                                              withExtension: fileExtension,
                                              subdirectory: filePath) {
                AsyncImage(url: imageURL) { result in
                    result.image?
                        .resizable()
                        .scaledToFit()
                }
            } else {
                Text("[Image not available]")
            }
        } else {
            Text("[Image not available]")
        }
    }
}

extension ImageProvider where Self == ResourceImageProvider {
    
    fileprivate static var resource: ResourceImageProvider { .init() }
}

#Preview(windowStyle: .plain) {
    LoadingView()
        .glassBackgroundEffect()
    
    LoadingFailedView()
        .glassBackgroundEffect()
    
    UserGuideView()
        .environment(ScenePhaseTracker())
        .glassBackgroundEffect()
}
