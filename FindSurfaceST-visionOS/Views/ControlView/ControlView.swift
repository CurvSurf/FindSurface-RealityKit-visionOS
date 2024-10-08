//
//  ControlView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

import FindSurface_visionOS

struct ControlView: View {
    
    @Environment(AppState.self) private var state
    @Environment(FindSurface.self) private var findSurface
    @Environment(ScenePhaseTracker.self) private var scenePhaseTracker
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @State private var showMesh: Bool = true
    
    var body: some View {
        @Bindable var state = state
        @Bindable var findSurface = findSurface
        
        VStack {
            Section {
                VStack(alignment: .leading) {
                    FeatureTypePicker(type: $findSurface.targetFeature)
                    
                    NumericTextField(label: "Accuracy [cm]: ", value: $findSurface.measurementAccuracy, minValue: 0.001, maxValue: 0.10)
                        .accessibilityLabel("Accuracy")
                        .accessibilityInputLabels(["Measurement Accuracy", "Accuracy"])
                    
                    NumericTextField(label: "Mean Distance [cm]: ", value: $findSurface.meanDistance, minValue: 0.001, maxValue: 0.50)
                        .accessibilityLabel("Distance")
                        .accessibilityInputLabels(["Mean Distance", "Average Distance", "Distance"])
                    
                    NumericTextField(label: "Seed Radius [cm]: ", value: $findSurface.seedRadius, minValue: 0.001, maxValue: 0.75)
                        .accessibilityLabel("Seed Radius")
                        .accessibilityInputLabels(["Touch Radius", "Seed Radius"])
                    
                    LateralExtensionStepper(level: $findSurface.lateralExtension).padding(.vertical, -4)
                        .accessibilityLabel("Lateral Extension")
                        .accessibilityInputLabels(["Lateral Extension", "Lateral", "Extension"])
                    
                    RadialExpansionStepper(level: $findSurface.radialExpansion).padding(.vertical, -4)
                        .accessibilityLabel("Radial Expansion")
                        .accessibilityInputLabels(["Radial Expansion", "Radial", "Expansion"])
                    
                    ShowHideToggle(label: "Show inlier points: ", show: $state.showInlierPoints)
                        .accessibilityLabel("Inlier")
                    
                    ShowHideToggle(label: "Show geometry outline: ", show: $state.showGeometryOutline)
                        .accessibilityLabel("Outline")
                    
                    HStack {
                        ClearSceneButton {
                            if scenePhaseTracker.activeScene.contains(.shareWindow) {
                                dismissWindow(sceneID: SceneID.shareWindow)
                            }
                            state.reset()
                        }
                        Button("Export") {
                            Task {
                                let content = await state.exportAsUSD()
                                
                                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("find-surface-results.usda")
                                try? content.write(to: fileURL, atomically: true, encoding: .utf8)
                                if scenePhaseTracker.activeScene.contains(.shareWindow) {
                                    dismissWindow(sceneID: SceneID.shareWindow)
                                }
                                openWindow(sceneID: SceneID.shareWindow, value: fileURL)
                            }
                        }
                        .disabled(state.geometryEntities.isEmpty)
                    }
                }
            } header: {
                ControlSectionHeader(isExpanded: $state.showResultPanel,
                                     showMesh: $showMesh)
                .onChange(of: showMesh) {
                    state.meshEntity.isEnabled = showMesh
                }
            }
        }
        .onChange(of: state.showGeometryOutline, initial: true) { _, newValue in
            state.enableGeometryOutline(newValue)
        }
        .onChange(of: state.showInlierPoints, initial: true) { _, newValue in
            state.enableInlierPoints(newValue)
        }
        .padding()
        .frame(width: 300, height: 490, alignment: .top)
        .background(.clear.opacity(0))
        .border(Color.white)
    }
}
