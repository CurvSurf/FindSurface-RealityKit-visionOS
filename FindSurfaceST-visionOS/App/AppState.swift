//
//  AppState.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import ARKit
import RealityKit
import QuartzCore
import Combine
import _RealityKit_SwiftUI
import AVKit

import FindSurface_visionOS

fileprivate let safetyDistance: Float = 5.0
fileprivate let safetyHeight: Float = 1.0
fileprivate let alertBoundary: Float = 0.75
fileprivate let alertShowingDistance: Float = max(safetyDistance - alertBoundary, 0)
fileprivate let boundaryShowingDistance: Float = max(alertShowingDistance - alertBoundary, 0)

@Observable
final class AppState {
    
    let sceneReconstructionProvider = SceneReconstructionProvider()
    let worldTrackingProvider = WorldTrackingProvider()
    let handTrackingProvider = HandTrackingProvider()
    var dataProviders: [any DataProvider] {
        [sceneReconstructionProvider, worldTrackingProvider, handTrackingProvider]
    }
    
    let rootEntity: Entity
    
    // mesh
    let meshEntity: Entity
    var meshEntities: [UUID: ModelEntity] = [:]
    
    private(set) var pointclouds: [UUID: [simd_float3]] = [:]
    private(set) var pointCount: Int = 0
    
    var visiblePoints: [simd_float3] {
        guard let deviceAnchor else { return [] }
        
        let points = pointclouds.values.flatMap { $0 }
        let origin = deviceAnchor.position
        let direction = deviceAnchor.forward
        // performs view frustum culling with an estimated fov angles
        // 120 degree in horizontal, 90 degree in vertical, plus 10 degree as a margin for each
        return points.filter { point in
            let pointDirection = point - origin
            let pointDirectionXZ = normalize(simd_float2(pointDirection.x, pointDirection.z))
            let pointDirectionYZ = normalize(simd_float2(pointDirection.y, pointDirection.z))
            let deviceDirectionXZ = normalize(simd_float2(direction.x, direction.z))
            let deviceDirectionYZ = normalize(simd_float2(direction.y, direction.z))
            let horizontalAngle = acos(dot(pointDirectionXZ, deviceDirectionXZ))
            let verticalAngle = acos(dot(pointDirectionYZ, deviceDirectionYZ))
            return horizontalAngle < (.pi * 65.0 / 180.0) && verticalAngle < (.pi * 50.0 / 180.0)
        }
    }
    
    func updatePointcloud(_ pointcloud: [simd_float3]?, forKey key: UUID) {
        guard let pointcloud else {
            if let removed = pointclouds.removeValue(forKey: key) {
                pointCount -= removed.count
            }
            return
        }
        
        if let removed = pointclouds.updateValue(pointcloud, forKey: key) {
            pointCount -= removed.count
        }
        pointCount += pointcloud.count
    }
    
    @MainActor
    func processMeshAnchorUpdates() async {
        for await update in sceneReconstructionProvider.anchorUpdates {
            switch update.event {
            case .added:    await anchorAdded(update.anchor)
            case .updated:  await anchorUpdated(update.anchor)
            case .removed:  await anchorRemoved(update.anchor)
            }
        }
    }
    
    @MainActor
    private func anchorAdded(_ anchor: MeshAnchor) async {
        let position = anchor.originFromAnchorTransform.position
        guard distance(position, simd_float3(0, position.y, 0)) < 5 else { return }
        guard let entity = await ModelEntity.generateWireframe(from: anchor) else { return }
        meshEntity.addChild(entity)
        meshEntities[anchor.id] = entity
        updatePointcloud(anchor.pointcloud, forKey: anchor.id)
    }
    
    @MainActor
    private func anchorUpdated(_ anchor: MeshAnchor) async {
        guard let entity = meshEntities[anchor.id],
              let shape = try? await ShapeResource.generateStaticMesh(from: anchor) else { return }
        let materials = entity.model?.materials ?? .mesh
        entity.model = ModelComponent(mesh: .generate(from: anchor), materials: materials)
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        entity.collision?.shapes = [shape]
        updatePointcloud(anchor.pointcloud, forKey: anchor.id)
    }
    
    @MainActor
    private func anchorRemoved(_ anchor: MeshAnchor) async {
        guard let entity = meshEntities[anchor.id] else { return }
        entity.removeFromParent()
        meshEntity.removeChild(entity)
        meshEntities.removeValue(forKey: anchor.id)
        updatePointcloud(nil, forKey: anchor.id)
    }
    
    // geometry
    let geometryEntity: Entity
    var geometryEntities: [UUID: GeometryEntity] = [:]
    
    var showGeometryOutline: Bool = true
    
    @MainActor
    func enableGeometryOutline(_ visible: Bool) {
        for (_, entity) in geometryEntities {
            entity.enableOutline(showGeometryOutline)
        }
    }
    
    private let inlierPointsEntity: Entity
    private var inlierPointsEntities: [UUID: ModelEntity] = [:]
    
    var showInlierPoints: Bool = true
    
    @MainActor
    func enableInlierPoints(_ visible: Bool) {
        inlierPointsEntity.isEnabled = visible
    }
    
    @MainActor
    func processWorldAnchorUpdates() async {
        for await update in worldTrackingProvider.anchorUpdates {
            switch update.event {
            case .added:    await anchorAdded(update.anchor)
            case .updated:  await anchorUpdated(update.anchor)
            case .removed:  await anchorRemoved(update.anchor)
            }
        }
    }
    
    @MainActor
    private func anchorAdded(_ anchor: WorldAnchor) async {
        if pendingObjects.keys.contains(anchor.id) {
            persistentObjects[anchor.id] = pendingObjects.removeValue(forKey: anchor.id)
        }
        
        guard let object = persistentObjects[anchor.id] else {
            do {
                try await worldTrackingProvider.removeAnchor(anchor)
            } catch {}
            return
        }
        resultMessages.append(.init(from: object))
        
        let geometry = await GeometryEntity.generateGeometryEntity(from: object)
        if !showGeometryOutline {
            geometry.enableOutline(false)
        }
        geometryEntity.addChild(geometry)
        geometryEntities[anchor.id] = geometry
        
        let inlierPoints = await ModelEntity.generatePointcloudEntity(from: object)
        
        inlierPointsEntity.addChild(inlierPoints)
        inlierPointsEntities[anchor.id] = inlierPoints
    }
    
    @MainActor
    private func anchorUpdated(_ anchor: WorldAnchor) async {
        
        let transform = Transform(matrix: anchor.originFromAnchorTransform)
        
        if let geometry = geometryEntities[anchor.id] {
            geometry.transform = transform
            if var object = geometry.components[PersistentComponent.self]?.object {
                object.object.extrinsics = transform.matrix
                geometry.components.set(PersistentComponent(object: object))
            }
        }
        
        if let attachment = attachmentEntities[anchor.id] {
            attachment.transform = transform
        }
        
        if let inlierPoints = inlierPointsEntities[anchor.id] {
            inlierPoints.transform = transform
        }
    }
    
    @MainActor
    private func anchorRemoved(_ anchor: WorldAnchor) async {
        
        if let geometry = geometryEntities.removeValue(forKey: anchor.id) {
            geometry.removeFromParent()
            geometryEntity.removeChild(geometry)
        }
        
        if let attachment = attachmentEntities.removeValue(forKey: anchor.id) {
            attachment.removeFromParent()
            attachmentEntity.removeChild(attachment)
        }
        
        if let inlierPoints = inlierPointsEntities.removeValue(forKey: anchor.id) {
            inlierPoints.removeFromParent()
            inlierPointsEntity.removeChild(inlierPoints)
        }
    }
    
    var deviceAnchor: DeviceAnchor? = nil
    
    @MainActor
    func processDeviceAnchorUpdates() async {
        await run(withFrequency: 90) {
            guard worldTrackingProvider.state == .running,
                  let anchor = self.worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()),
                  anchor.isTracked else { return }
            
            deviceAnchor = anchor
            
            await self.orientAttachments(to: anchor)
            let distance = distance(anchor.position, simd_float3(0, anchor.position.y, 0))
            if distance > boundaryShowingDistance {
                boundary.isEnabled = true
                let opacity = min(max((distance - boundaryShowingDistance) / alertBoundary, 0.0), 1.0) * 0.5
                boundary.components.set(OpacityComponent(opacity: opacity))
            } else {
                boundary.isEnabled = false
                boundary.components.set(OpacityComponent(opacity: 0))
            }
            if distance > alertShowingDistance {
                warningView?.isEnabled = true
                warningView?.look(at: anchor.position,
                                  from: anchor.position + 0.80 * anchor.forward + 0.20 * anchor.up,
                                  relativeTo: nil,
                                  forward: .positiveZ)
            } else {
                warningView?.isEnabled = false
            }
        }
    }
    
    // attachment
    let attachmentEntity: Entity
    
    var showAttachments: Bool {
        get { attachmentEntity.isEnabled }
        set { attachmentEntity.isEnabled = newValue }
    }
    
    var attachmentEntities: [UUID: ViewAttachmentEntity] = [:]

    @MainActor
    private func orientAttachments(to anchor: DeviceAnchor) async {
        
        for (key, attachment) in attachmentEntities {
            guard let geometry = geometryEntities[key],
                  let object = geometry.components[PersistentComponent.self]?.object else { continue }
            
            switch object {
            case .plane(_, let plane, _, _):        await orient(attachment, with: plane, towards: anchor.position)
            case .sphere(_, let sphere, _, _):      await orient(attachment, with: sphere, towards: anchor.position)
            case .cylinder(_, let cylinder, _, _):  await orient(attachment, with: cylinder, towards: anchor.position)
            case .cone(_, let cone, _, _):          await orient(attachment, with: cone, towards: anchor.position)
            case .torus(_, let torus, _, _):        await orient(attachment, with: torus, towards: anchor.position)
            }
        }
        
        if shouldLocatePanelInitially {
            panelEntity?.look(at: anchor.position,
                              from: anchor.position + 0.7 * normalize(anchor.forward + anchor.right),
                              relativeTo: nil, forward: .positiveZ)
            shouldLocatePanelInitially = false
        }
    }
    
    private func orient(_ attachment: ViewAttachmentEntity, with plane: Plane, towards deviceLocation: simd_float3) async {
        let normal = plane.normal
        let center = plane.center
        
        let isHorizontalPlane = abs(normal.y) > cos(.pi / 12)
        if isHorizontalPlane {
            let position = center + 0.20 * normal
            await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
        } else {
            let at = center + normal
            let position = center + 0.20 * normal
            await attachment.look(at: at, from: position, relativeTo: nil, forward: .positiveZ)
        }
    }
    
    private func orient(_ attachment: ViewAttachmentEntity, with sphere: Sphere, towards deviceLocation: simd_float3) async {
        let radius = sphere.radius
        let center = sphere.center
        
        let position = center + (0.15 + radius) * normalize(deviceLocation - center)
        await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
    }
    
    private func orient(_ attachment: ViewAttachmentEntity, with cylinder: Cylinder, towards deviceLocation: simd_float3) async {
        let center = cylinder.center
        let axis = cylinder.axis
        let top = cylinder.top
        let radius = cylinder.radius
        
        let isLyingDown = abs(axis.y) * sqrt(2.0) < 1
        let isAboveEyeLevel = top.y > deviceLocation.y + 0.10
        if isLyingDown || isAboveEyeLevel {
            let position = center + (0.15 + radius) * normalize(deviceLocation - center)
            await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
        } else {
            let position = top + 0.15 * axis
            await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
        }
    }
    
    private func orient(_ attachment: ViewAttachmentEntity, with cone: Cone, towards deviceLocation: simd_float3) async {
        let axis = cone.axis
        let top = cone.top
        let bottom = cone.bottom
        let center = cone.center
        let bottomRadius = cone.bottomRadius
        
        let isLyingDown = abs(axis.y) * sqrt(2.0) < 1
        let isAboveEyeLevel = top.y > deviceLocation.y + 0.10
        if isLyingDown || isAboveEyeLevel {
            let position = center + (0.15 + bottomRadius) * normalize(deviceLocation - center)
            await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
        } else {
            let isUpsideDown = axis.y < 0
            let position = isUpsideDown ? bottom - 0.15 * axis : top + 0.15 * axis
            await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
        }
    }
    
    private func orient(_ attachment: ViewAttachmentEntity, with torus: Torus, towards deviceLocation: simd_float3) async {
        let axis = torus.axis
        let center = torus.center
        let tubeRadius = torus.tubeRadius
        let meanRadius = torus.meanRadius
        
        let isLyingDown = abs(axis.y) * sqrt(2.0) < 1
        let isAboveEyeLevel = center.y + tubeRadius > deviceLocation.y + 0.10
        if isLyingDown || isAboveEyeLevel {
            let position = center + (0.15 + meanRadius + tubeRadius) * normalize(deviceLocation - center)
            await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
        } else {
            let position = center + (0.15 + tubeRadius) * axis
            await attachment.look(at: deviceLocation, from: position, relativeTo: nil, forward: .positiveZ)
        }
    }
    
    // hand
    let hands: Hands
    
    @MainActor
    func processHandAnchorUpdates() async {
        
        for await update in handTrackingProvider.anchorUpdates {
            let anchor = update.anchor
            
            hands.isEnabled = anchor.isTracked
            guard anchor.isTracked,
                  let handSkeleton = anchor.handSkeleton else {
                continue
            }
            
            let hand = hands[anchor.chirality]
//            hand.transform = Transform(matrix: anchor.originFromAnchorTransform)
            let originFromAnchorTransform = anchor.originFromAnchorTransform
            
            for location in TrackerLocation.allCases {
                
                let jointName = location.jointName
                let joint = handSkeleton.joint(jointName)
                let tracker = hand[location]
                tracker.isEnabled = anchor.isTracked
                
                if location == .wrist {
                    let rotation = simd_float4x4(.init(0, 1, 0, 0),
                                                 .init(1, 0, 0, 0),
                                                 .init(0, 0, 1, 0),
                                                 .init(0, 0, 0, 1))
                    let matrix = originFromAnchorTransform * joint.anchorFromJointTransform * rotation
                    tracker.transform = Transform(matrix: matrix)
                } else {
                    tracker.transform = Transform(matrix: originFromAnchorTransform * joint.anchorFromJointTransform)
                }
                hand[location] = tracker
            }
            
            await recognizeGestures()
        }
        
    }
    
    private var rightHandMiddleFingerPinchingFrameCount: Int = 0
    private var leftHandMiddleFingerPinchingFrameCount: Int = 0
    
    var shouldLocatePanelInitially = false
    var panelEntity: ViewAttachmentEntity? = nil {
        didSet {
            if let oldValue {
                oldValue.removeFromParent()
                rootEntity.removeChild(oldValue)
            }
            if let panelEntity {
                rootEntity.addChild(panelEntity)
            }
        }
    }
    
    @MainActor
    private func recognizeGestures() async {
        
        if hands.rightHand.contacts(.thumbTip, .middleFingerTip) {
            rightHandMiddleFingerPinchingFrameCount = min(rightHandMiddleFingerPinchingFrameCount + 1, 5)
        } else {
            rightHandMiddleFingerPinchingFrameCount = max(rightHandMiddleFingerPinchingFrameCount - 1, 0)
        }
        
        if hands.leftHand.contacts(.thumbTip, .middleFingerTip) {
            leftHandMiddleFingerPinchingFrameCount = min(leftHandMiddleFingerPinchingFrameCount + 1, 5)
        } else {
            leftHandMiddleFingerPinchingFrameCount = max(leftHandMiddleFingerPinchingFrameCount - 1, 0)
        }
        
        Task {
            await updateControlPanelPosition()
        }
    }
    
    @MainActor
    private func updateControlPanelPosition() async {
        
        guard let deviceAnchor,
              let panelEntity,
              leftHandMiddleFingerPinchingFrameCount < 4 &&
              rightHandMiddleFingerPinchingFrameCount > 3 else { return }
        
        let hand = hands.rightHand
        let contactPosition = (hand.thumbTip.position + hand.middleFingerTip.position) * 0.5
        let wristPosition = hand.wrist.position
        let direction = normalize(contactPosition - wristPosition)
        let upward = simd_float3(0, 1, 0)
        let outward = normalize(cross(direction, upward))
        let right = deviceAnchor.right
        var panelLocation = wristPosition + normalize(outward + direction) * 0.3 + upward * 0.20
        
        if showResultPanel {
            panelLocation -= right * 0.30
        } else {
            panelLocation -= right * 0.30
        }
        
        panelEntity.isEnabled = true
        panelEntity.look(at: deviceAnchor.position, from: panelLocation, relativeTo: nil, forward: .positiveZ)
    }
    
    // objects
    var pendingObjects: [UUID: PersistentObject] = [:]
    var persistentObjects: [UUID: PersistentObject] = [:]
    
    var showResultPanel: Bool = true
    
    var resultMessages: [ResultMessage] = []
    
    var errorCode: ErrorCode? = nil
    
    var showPanels: Bool {
        get { panelEntity?.isEnabled ?? false }
        set { panelEntity?.isEnabled = newValue }
    }
    
    private let boundary: ModelEntity
    var warningView: ViewAttachmentEntity? = nil {
        didSet {
            if let oldValue {
                oldValue.removeFromParent()
                rootEntity.removeChild(oldValue)
            }
            if let warningView {
                rootEntity.addChild(warningView)
            }
        }
    }
    
    @MainActor
    init() {
        
        let rootEntity = Entity()
        
        let boundary = ModelEntity(mesh: .generateCylindricalSurface(radius: safetyDistance, height: safetyHeight, useClockwiseTriangleWinding: true),
                                   materials: [UnlitMaterial(color: .orange)])
        boundary.components.set(OpacityComponent(opacity: 0.0))
        boundary.position = .init(0, safetyHeight * 0.5, 0)
        boundary.isEnabled = false
        rootEntity.addChild(boundary)
        
        let meshEntity = Entity()
        rootEntity.addChild(meshEntity)
        
        let geometryEntity = Entity()
        rootEntity.addChild(geometryEntity)
        
        let inlierPointsEntity = Entity()
        rootEntity.addChild(inlierPointsEntity)
        
        let attachmentEntity = Entity()
        rootEntity.addChild(attachmentEntity)
        
        let hands = Hands()
        hands.isEnabled = false
        rootEntity.addChild(hands)
        
        let seedAreaIndicator = SeedAreaIndicator()
        seedAreaIndicator.isEnabled = false
        rootEntity.addChild(seedAreaIndicator)
        
        let seedAreaControl = SeedAreaIndicator()
        seedAreaControl.isEnabled = false
        rootEntity.addChild(seedAreaControl)
        
        self.rootEntity = rootEntity
        self.meshEntity = meshEntity
        self.geometryEntity = geometryEntity
        self.inlierPointsEntity = inlierPointsEntity
        self.attachmentEntity = attachmentEntity
        self.hands = hands
        self.seedAreaIndicator = seedAreaIndicator
        self.seedAreaControl = seedAreaControl
        self.boundary = boundary
    }
    
    @MainActor
    func reset() {
        Task {
            for key in persistentObjects.keys {
                await removeAnchor(id: key)
            }
            persistentObjects.removeAll()
            resultMessages.removeAll()
        }
    }
    
    @MainActor
    func removeAnchor(id: UUID) async {
        guard persistentObjects.removeValue(forKey: id) != nil else { return }
        do {
            try await worldTrackingProvider.removeAnchor(forID: id)
        } catch {}
    }
    
    var centerOfBothIndexFingerTips: simd_float3? {
        let left = hands.leftHand.indexFingerTip
        let right = hands.rightHand.indexFingerTip
        guard left.isEnabled && right.isEnabled else { return nil }
        return (left.position + right.position) * 0.5
    }
    
    let seedAreaIndicator: SeedAreaIndicator
    let seedAreaControl: SeedAreaIndicator
    var diameterLabel: ViewAttachmentEntity? = nil {
        didSet {
            if let oldValue {
                oldValue.removeFromParent()
                rootEntity.removeChild(oldValue)
            }
            if let diameterLabel {
                rootEntity.addChild(diameterLabel)
            }
        }
    }
    
    @ObservationIgnored var animationSubscription: AnyCancellable? = nil
    
    @MainActor
    func flashAreaIndicator(at location: simd_float3, touchRadius: Float) async {
        
        guard let deviceAnchor else { return }
        
        animationSubscription?.cancel()
        animationSubscription = nil
        
        let origin = deviceAnchor.position
        let direction = normalize(location - origin)
        
        guard let result = meshEntity.scene?.raycast(origin: origin, direction: direction, query: .nearest).first else { return }
        
        seedAreaIndicator.isEnabled = true
        seedAreaIndicator.position = result.position
        seedAreaIndicator.normal = result.normal
        seedAreaIndicator.radius = touchRadius
        let flashing = FromToByAnimation<Float>(name: "flashing",
                                                from: 0.8,
                                                to: 0.0,
                                                duration: 1.0,
                                                timing: .easeInOut,
                                                bindTarget:.opacity)
        let animation = try! AnimationResource.generate(with: flashing)
        let handle = seedAreaIndicator.playAnimation(animation)
        animationSubscription = seedAreaIndicator.scene?.publisher(for: AnimationEvents.PlaybackCompleted.self)
            .filter { $0.playbackController == handle }
            .sink { [weak self] _ in
                self?.seedAreaIndicator.isEnabled = false
                self?.animationSubscription = nil
            }
    }
    
    var failSign: ViewAttachmentEntity? = nil {
        didSet {
            if let oldValue {
                oldValue.removeFromParent()
                rootEntity.removeChild(oldValue)
            }
            if let failSign {
                rootEntity.addChild(failSign)
            }
        }
    }
    @ObservationIgnored var failSignAnimationSubscription: AnyCancellable? = nil
    
    @MainActor
    func showFailSign(at location: simd_float3) async {
        
        guard let deviceAnchor,
              let failSign else { return }
        
        failSignAnimationSubscription?.cancel()
        failSignAnimationSubscription = nil
        
        let origin = deviceAnchor.position
        let direction = normalize(location - origin)
        
        guard let result = meshEntity.scene?.raycast(origin: origin, direction: direction, query: .nearest).first else { return }
        
        AudioServicesPlaySystemSound(1053)
        failSign.isEnabled = true
        let position = result.position + 0.05 * result.normal
        failSign.look(at: deviceAnchor.position, from: position, relativeTo: nil, forward: .positiveZ)
    
        let flashing = FromToByAnimation<Float>(name: "flashing",
                                                from: 0.8,
                                                to: 0.0,
                                                duration: 1.0,
                                                timing: .easeInOut,
                                                bindTarget:.opacity)
        let animation = try! AnimationResource.generate(with: flashing)
        let handle = failSign.playAnimation(animation)
        failSignAnimationSubscription = failSign.scene?.publisher(for: AnimationEvents.PlaybackCompleted.self)
            .filter { $0.playbackController == handle }
            .sink { [weak self] _ in
                failSign.isEnabled = false
                self?.failSignAnimationSubscription = nil
            }
    }
    
    @MainActor
    func process(_ result: FindSurface.Result) async throws {
        
        if case .none = result {
            return
        }
        
        AudioServicesPlaySystemSound(1100)
        
        let object: PersistentObject = switch result {
        case .foundPlane(var plane, let inliers, let rmsError): {
            plane.align(withCamera: deviceAnchor!.position)
            let name = "Plane\(persistentObjects.count)"
            let transform = plane.transform
            let inliers = inliers.map { simd_make_float3(transform * simd_float4($0, 1)) }
            return .plane(name, plane, inliers, rmsError)
        }()
            
        case .foundSphere(let sphere, let inliers, let rmsError): {
            let name = "Sphere\(persistentObjects.count)"
            let transform = sphere.transform
            let inliers = inliers.map { simd_make_float3(transform * simd_float4($0, 1)) }
            return .sphere(name, sphere, inliers, rmsError)
        }()
            
        case .foundCylinder(var cylinder, let inliers, let rmsError): {
            cylinder.align()
            let name = "Cylinder\(persistentObjects.count)"
            let transform = cylinder.transform
            let inliers = inliers.map { simd_make_float3(transform * simd_float4($0, 1)) }
            return .cylinder(name, cylinder, inliers, rmsError)
        }()
            
        case .foundCone(let cone, let inliers, let rmsError): {
            let name = "Cone\(persistentObjects.count)"
            let transform = cone.transform
            let inliers = inliers.map { simd_make_float3(transform * simd_float4($0, 1)) }
            return .cone(name, cone, inliers, rmsError)
        }()
            
        case .foundTorus(var torus, let inliers, let rmsError): {
            torus.align()
            let name = "Torus\(persistentObjects.count)"
            let transform = torus.transform
            let inliers = inliers.map { simd_make_float3(transform * simd_float4($0, 1)) }
            return .torus(name, torus, inliers, rmsError)
        }()
            
        default: fatalError()
        }
        
        let extrinsics = object.object.extrinsics
        let anchor = WorldAnchor(originFromAnchorTransform: extrinsics)
        pendingObjects[anchor.id] = object
        try await worldTrackingProvider.addAnchor(anchor)
    }
}

@MainActor
fileprivate func run(withFrequency hz: UInt64, function: () async -> Void) async {
    while true {
        if Task.isCancelled {
            return
        }
        
        let nanosecondsToSleep: UInt64 = NSEC_PER_SEC / hz
        
        do {
            try await Task.sleep(nanoseconds: nanosecondsToSleep)
        } catch {
            return
        }
        
        await function()
    }
}
