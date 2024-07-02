//
//  ImmersiveView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/12/24.
//

import SwiftUI
import ARKit
import RealityKit

import FindSurface_visionOS

fileprivate struct DiameterLabel: View {
    @Environment(FindSurface.self) private var findSurface
    var body: some View {
        let diameter = String(format: "%.1f", findSurface.seedRadius * 200) // diameter(2) * centimeter(100)
        Text("\(diameter) cm")
            .padding()
            .glassBackgroundEffect()
    }
}

fileprivate struct WarningView: View {
    var body: some View {
        VStack {
            Text("⚠️ WARNING ⚠️")
                .font(.title)
            Text("This app limits the scan range to a radius of 5 meters from the point where the app is launched. The app will not function properly outside of this area.")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 400)
        .padding()
        .glassBackgroundEffect()
    }
}

@MainActor
struct ImmersiveView: View {

    private enum Attachments {
        case panels
        case failSign
        case radius
        case warning
    }
    
    @Environment(AppState.self) private var state
    @Environment(SessionManager.self) private var sessionManager
    @Environment(FindSurface.self) private var findSurface
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var magnifyingStarted: Bool = false
    @State private var initialRadius: Float = 0.01
    
    var body: some View {
        
        RealityView { content, attachments in
            content.add(state.rootEntity)
            
            if let panelEntity = attachments.entity(for: Attachments.panels) {
                panelEntity.isEnabled = true
                state.shouldLocatePanelInitially = true
                state.panelEntity = panelEntity
            }
            
            for key in state.geometryEntities.keys {
                guard let attachment = attachments.entity(for: key) else { continue }
                
                attachment.isEnabled = true
                attachment.removeFromParent()
                state.attachmentEntity.addChild(attachment)
                state.attachmentEntities[key] = attachment
            }
            
            if let failSign = attachments.entity(for: Attachments.failSign) {
                failSign.isEnabled = false
                state.failSign = failSign
            }
            
            if let radiusText = attachments.entity(for: Attachments.radius) {
                radiusText.isEnabled = false
                state.diameterLabel = radiusText
            }
            
            if let warningView = attachments.entity(for: Attachments.warning) {
                warningView.isEnabled = false
                state.warningView = warningView
            }
            
            Task {
                await sessionManager.run(with: state.dataProviders)
            }
            
        } update: { update, attachments in
            
            for key in state.geometryEntities.keys {
                guard let attachment = attachments.entity(for: key) else { continue }
                
                attachment.isEnabled = true
                if !state.attachmentEntities.keys.contains(key) {
                    attachment.removeFromParent()
                    state.attachmentEntity.addChild(attachment)
                    state.attachmentEntities[key] = attachment
                }
            }
            
        } attachments: {
            
            Attachment(id: Attachments.panels) {
                PanelView()
                    .environment(state)
            }
            
            ForEach(Array(state.geometryEntities.keys), id: \.self) { key in
                if let entity = state.geometryEntities[key],
                   let object = entity.components[PersistentComponent.self]?.object {
                    Attachment(id: key) {
                        ResultAttachmentView(id: key, messageItem: .init(from: object))
                            .environment(state)
                    }
                }
            }
            
            Attachment(id: Attachments.failSign) {
                FailSignView()
            }
            
            Attachment(id: Attachments.radius) {
                DiameterLabel()
                    .environment(findSurface)
            }
            
            Attachment(id: Attachments.warning) {
                WarningView()
            }
        }
        .upperLimbVisibility(.visible)
        .task {
            await sessionManager.monitorSessionEvents { error in
                state.errorCode = .sessionErrorOccurred(.init(from: error))
            }
        }
        .task {
            await state.processMeshAnchorUpdates()
        }
        .task {
            await state.processWorldAnchorUpdates()
        }
        .task {
            await state.processDeviceAnchorUpdates()
        }
        .task {
            await state.processHandAnchorUpdates()
        }
        .onSpatialTapGesture { location, entity in
            Task {
                do {
                    let result = try await findSurface.perform {
                        await state.flashAreaIndicator(at: location, touchRadius: findSurface.seedRadius)
                        let points = state.visiblePoints
                        let index = points.enumerated().map { k, point in
                            (k, distance_squared(location, point))
                        }.min { $0.1 < $1.1 }?.0
                        
                        guard let index,
                              distance(points[index], location) < 0.30 else { return nil }
                        return (points, index)
                    }
                    
                    guard let result else { return }
                    
                    if case let .none(rmsError) = result {
                        state.resultMessages.append(.init("Failed: \(rmsError)"))
                        await state.showFailSign(at: location)
                    } else {
                        try await state.process(result)
                    }
                    
                } catch let error as FindSurface.Failure {
                    switch error {
                    case .memoryAllocationFailure:      state.errorCode = .findSurfaceError("memory allocation failed")
                    case let .invalidArgument(reason):  state.errorCode = .findSurfaceError(reason)
                    case let .invalidOperation(reason): state.errorCode = .findSurfaceError(reason)
                    }
                } catch let error as WorldTrackingProvider.Error {
                    
                } catch {
                    state.errorCode = .findSurfaceError("\(error)")
                }
            }
        }
        .gesture(
            MagnifyGesture()
                .onChanged { value in
                    if !magnifyingStarted {
                        magnifyingStarted = true
                        initialRadius = findSurface.seedRadius
                        if let device = state.deviceAnchor {
                            let indicatorPosition = state.centerOfBothIndexFingerTips ?? (device.position + device.forward * 0.5)
                            let position = indicatorPosition + 0.50 * normalize(indicatorPosition - device.position)
                            state.seedAreaControl.position = position
                        }
                    }
                    state.seedAreaControl.isEnabled = true
                    state.diameterLabel?.isEnabled = true
                    
                    if let device = state.deviceAnchor,
                       let radiusText = state.diameterLabel {
                        let indicator = state.seedAreaControl
                        indicator.normal = normalize(device.position - indicator.position)
                        findSurface.seedRadius = max(min(initialRadius * Float(value.magnification), 0.75), 0.001)
                        radiusText.look(at: device.position, from: indicator.position + 0.05 * indicator.normal, relativeTo: nil, forward: .positiveZ)
                    }
                }
                .onEnded { value in
                    state.seedAreaControl.isEnabled = false
                    state.diameterLabel?.isEnabled = false
                    magnifyingStarted = false
                }
        )
        .onChange(of: findSurface.seedRadius, initial: true) { _, radius in
            state.seedAreaIndicator.radius = radius
            state.seedAreaControl.radius = radius
        }
        .onAppear {
            state.loadFromAppStorage()
            findSurface.loadFromAppStorage()
            do {
                state.persistentObjects = try .load()
            } catch {
                if let error = error as? ErrorCode {
                    state.errorCode = error
                }
            }
        }
        .onDisappear {
            state.saveToAppStorage()
            findSurface.saveToAppStorage()
            do {
                try state.persistentObjects.save()
            } catch {
                if let error = error as? ErrorCode {
                    state.errorCode = error
                }
            }
        }
        .onChange(of: scenePhase) { _, scenePhase in
            if scenePhase != .active {
                state.saveToAppStorage()
                findSurface.saveToAppStorage()
            }
        }
//        .onChange(of: findSurface.seedRadius, initial: true) { _, seedRadius in
//            state.seedAreaIndicator.radius = seedRadius
//        }
    }
}

//#Preview(immersionStyle: .mixed) {
//    ImmersiveView()
//}
