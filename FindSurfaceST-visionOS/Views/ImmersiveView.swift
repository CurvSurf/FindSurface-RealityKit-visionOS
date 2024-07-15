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
            
            if let radiusLabel = attachments.entity(for: Attachments.radius) {
                state.seedAreaControl.label = radiusLabel
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
            
            for (key, pendingResult) in state.pendingResults {
                guard let attachment = attachments.entity(for: key) else { continue }
                
                attachment.isEnabled = true
                let offset = 0.15 * (state.deviceAnchor?.backward ?? .init(0, 1, 0))
                attachment.position = pendingResult.dialogLocation + offset
                if !state.attachmentEntities.keys.contains(key) {
                    state.attachmentEntity.addChild(attachment)
                    state.attachmentEntities[key] = attachment
                }
            }
            
        } attachments: {
            
            Attachment(id: Attachments.panels) {
                PanelView()
                    .environment(state)
            }
            
            if !state.geometryEntities.isEmpty {
                ForEach(Array(state.geometryEntities.keys), id: \.self) { key in
                    if let entity = state.geometryEntities[key],
                       let object = entity.components[PersistentComponent.self]?.object {
                        Attachment(id: key) {
                            ResultAttachmentView(id: key, messageItem: .init(from: object))
                                .environment(state)
                        }
                    }
                }
            }
            
            Attachment(id: Attachments.failSign) {
                FailSignView()
            }
            
            Attachment(id: Attachments.radius) {
                RadiusLabel()
                    .environment(findSurface)
            }
            
            Attachment(id: Attachments.warning) {
                WarningView()
            }
            
            if !state.pendingResults.isEmpty {
                ForEach(Array(state.pendingResults), id: \.key) { (key, pendingResult) in
                    Attachment(id: key) {
                        PendingResultView(key: key, pendingResult: pendingResult)
                            .environment(state)
                    }
                }
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
        .onSpatialTapGesture(target: state.meshEntity) { location, entity in
            Task {
                do {
                    let targetFeature = findSurface.targetFeature
                    let result = try await findSurface.perform {
                        await state.flashAreaIndicator(at: location, seedRadius: findSurface.seedRadius)
                        
                        guard let i = state.pickPoint(near: location, entity: entity) else { return nil }
                        let id = UUID(uuidString: entity.name)
                        let points = state.generateVisiblePoints(id, i)

                        await state.flashPickedPoint(at: points[0])
                        await state.flashGesturePoint(at: location)
                        
                        return ([location] + points, 0)
                    }
                    
                    guard var result else { return }
                    
                    if case let .none(rmsError) = result {
                        state.resultMessages.append(.init("Failed: \(rmsError)"))
                        await state.showFailSign(at: location)
                        return
                    }
                    
                    let allowCylinderInsteadOfCone = findSurface.conversionOptions.contains(.coneToCylinder)
                    let allowCylinderInsteadOfTorus = findSurface.conversionOptions.contains(.torusToCylinder)
                    let allowSphereInsteadOfTorus = findSurface.conversionOptions.contains(.torusToSphere)
                    
                    let predicate = { (point: simd_float3) -> Bool in
                        return point != location
                    }
                    result = switch result {
                    case let .foundPlane(plane, inliers, rmsError): .foundPlane(plane, inliers.filter(predicate), rmsError)
                    case let .foundSphere(sphere, inliers, rmsError): .foundSphere(sphere, inliers.filter(predicate), rmsError)
                    case let .foundCylinder(cylinder, inliers, rmsError): .foundCylinder(cylinder, inliers.filter(predicate), rmsError)
                    case let .foundCone(cone, inliers, rmsError): .foundCone(cone, inliers.filter(predicate), rmsError)
                    case let .foundTorus(torus, inliers, rmsError): .foundTorus(torus, inliers.filter(predicate), rmsError)
                    default: result
                    }
                    
                    switch result {
                    case .foundCylinder:
                        if targetFeature == .cone && allowCylinderInsteadOfCone {
                            state.pendingResults[.init()] = .init(result: result,
                                                                  targetFeature: targetFeature,
                                                                  foundFeature: .cylinder,
                                                                  dialogLocation: location)
                            return
                        } else if targetFeature == .torus && allowCylinderInsteadOfTorus {
                            state.pendingResults[.init()] = .init(result: result,
                                                                targetFeature: targetFeature,
                                                                foundFeature: .cylinder,
                                                                  dialogLocation: location)
                            return
                        }
                    case .foundSphere:
                        if targetFeature == .torus && allowSphereInsteadOfTorus {
                            state.pendingResults[.init()] = .init(result: result,
                                                                  targetFeature: targetFeature,
                                                                  foundFeature: .sphere,
                                                                  dialogLocation: location)
                            return
                        }
                    default: break
                    }
                    
                    try await state.process(result)
                    
                } catch let error as FindSurface.Failure {
                    switch error {
                    case .memoryAllocationFailure:      state.errorCode = .findSurfaceError("memory allocation failed")
                    case let .invalidArgument(reason):  state.errorCode = .findSurfaceError(reason)
                    case let .invalidOperation(reason): state.errorCode = .findSurfaceError(reason)
                    }
                } catch _ as WorldTrackingProvider.Error {
                    // TODO: make it handle WorldTrackingProvider.Error
                    //       What state.process(_:) can throw is
                    //       an exception saying that `WorldTrackingProvider` failed to add world anchor.
                    //       We don't know why it happens and what to do.
                    //       Also there is not much information about it in the documentation.
                    //       So we don't do anything about it until we figure out
                    //        what causes it and what we can do not to make it happen.
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
                    
                    if let device = state.deviceAnchor {
                        let indicator = state.seedAreaControl
                        indicator.look(at: device.position, from: indicator.position, relativeTo: nil, forward: .positiveZ)
                        let radius = max(min(initialRadius * Float(value.magnification), 0.75), 0.001)
                        findSurface.seedRadius = radius
                        state.seedAreaIndicator.radius = radius
                        state.seedAreaControl.radius = radius
                    }
                }
                .onEnded { value in
                    state.seedAreaControl.isEnabled = false
                    magnifyingStarted = false
                }
        )
        .onAppear {
            state.loadFromAppStorage()
            findSurface.loadFromAppStorage()
            state.seedAreaIndicator.radius = findSurface.seedRadius
            state.seedAreaControl.radius = findSurface.seedRadius
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
