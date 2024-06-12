//
//  SpatialTapGesture.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI
import RealityKit
import simd

struct SpatialTapGestureModifier<SourceCoordinateSpace: CoordinateSpaceProtocol>: ViewModifier {
    
    let sourceSpace: SourceCoordinateSpace
    let destinationSpace: SceneRealityCoordinateSpace
    let action: (simd_float3, Entity) -> Void

    func body(content: Content) -> some View {
        content.gesture(
            SpatialTapGesture().targetedToAnyEntity().onEnded { event in
                let location = event.convert(event.location3D, from: sourceSpace, to: destinationSpace)
                action(location, event.entity)
            }
        )
    }
}

struct SpatialTapGestureWithTargetModifier<SourceCoordinateSpace: CoordinateSpaceProtocol>: ViewModifier {
    
    let sourceSpace: SourceCoordinateSpace
    let destinationSpace: SceneRealityCoordinateSpace
    let target: Entity
    let action: (simd_float3, Entity) -> Void

    func body(content: Content) -> some View {
        content.gesture(
            SpatialTapGesture().targetedToEntity(target).onEnded { event in
                let location = event.convert(event.location3D, from: sourceSpace, to: destinationSpace)
                action(location, event.entity)
            }
        )
    }
}

struct SpatialTapGestureWithPredicateModifier<SourceCoordinateSpace: CoordinateSpaceProtocol>: ViewModifier {
    
    let sourceSpace: SourceCoordinateSpace
    let destinationSpace: SceneRealityCoordinateSpace
    let predicate: QueryPredicate<Entity>
    let action: (simd_float3, Entity) -> Void
    
    func body(content: Content) -> some View {
        content.gesture(
            SpatialTapGesture().targetedToEntity(where: predicate).onEnded { event in
                let location = event.convert(event.location3D, from: sourceSpace, to: destinationSpace)
                action(location, event.entity)
            }
        )
    }
}

extension View {
    
    func onSpatialTapGesture<S>(from source: S = LocalCoordinateSpace.local,
                                to destination: SceneRealityCoordinateSpace = .scene,
                                action: @escaping (simd_float3, Entity) -> Void
    ) -> some View where S: CoordinateSpaceProtocol {
        modifier(SpatialTapGestureModifier(sourceSpace: source, destinationSpace: destination, action: action))
    }
    
    func onSpatialTapGesture<S>(from source: S = LocalCoordinateSpace.local,
                                to destination: SceneRealityCoordinateSpace = .scene,
                                action: @escaping (simd_float3) -> Void
    ) -> some View where S: CoordinateSpaceProtocol {
        onSpatialTapGesture(from: source, to: destination) { location, _ in
            action(location)
        }
    }
    
    func onSpatialTapGesture<S>(from source: S = LocalCoordinateSpace.local,
                                to destination: SceneRealityCoordinateSpace = .scene,
                                target: Entity,
                                action: @escaping (simd_float3, Entity) -> Void
    ) -> some View where S: CoordinateSpaceProtocol {
        modifier(SpatialTapGestureWithTargetModifier(sourceSpace: source, destinationSpace: destination, target: target, action: action))
    }
    
    func onSpatialTapGesture<S>(from source: S = LocalCoordinateSpace.local,
                                to destination: SceneRealityCoordinateSpace = .scene,
                                target: Entity,
                                action: @escaping (simd_float3) -> Void
    ) -> some View where S: CoordinateSpaceProtocol {
        onSpatialTapGesture(from: source, to: destination, target: target) { location, _ in
            action(location)
        }
    }
    
    func onSpatialTapGesture<S>(from source: S = LocalCoordinateSpace.local,
                                to destination: SceneRealityCoordinateSpace = .scene,
                                predicate: QueryPredicate<Entity>,
                                action: @escaping (simd_float3, Entity) -> Void
    ) -> some View where S: CoordinateSpaceProtocol {
        modifier(SpatialTapGestureWithPredicateModifier(sourceSpace: source, destinationSpace: destination, predicate: predicate, action: action))
    }
    
    func onSpatialTapGesture<S>(from source: S = LocalCoordinateSpace.local,
                                to destination: SceneRealityCoordinateSpace = .scene,
                                predicate: QueryPredicate<Entity>,
                                action: @escaping (simd_float3) -> Void
    ) -> some View where S: CoordinateSpaceProtocol {
        onSpatialTapGesture(from: source, to: destination, predicate: predicate) { location, _ in
            action(location)
        }
    }
}

