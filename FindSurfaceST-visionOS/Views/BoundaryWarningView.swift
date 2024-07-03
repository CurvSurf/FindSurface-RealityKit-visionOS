//
//  BoundaryWarningView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 7/3/24.
//

import Foundation
import SwiftUI

struct WarningView: View {
    var body: some View {
        VStack {
            Text("⚠️ WARNING ⚠️")
                .font(.title)
            Text("This app limits the scan range to a radius of \(String(format: "%d", Int(safetyDistance))) meters from the point where the app is launched. The app will not function properly outside of this area.")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 400)
        .padding()
        .glassBackgroundEffect()
    }
}

import RealityKit

#Preview(immersionStyle: .mixed) {
    RealityView { content, attachments in
        let boundary = ModelEntity(mesh: .generateCylindricalSurface(radius: 5, height: 1, useClockwiseTriangleWinding: true),
                                   materials: [UnlitMaterial(color: .orange.withAlphaComponent(0.2))])
        
        boundary.position = .init(0, 0, 2.6)
        content.add(boundary)
        
        if let warningView = attachments.entity(for: "Preview Warning") {
            warningView.look(at: .init(0, 1, 0), from: .init(0, 1.2, -1), relativeTo: nil, forward: .positiveZ)
            content.add(warningView)
        }
    } attachments: {
        Attachment(id: "Preview Warning") {
            WarningView()
        }
    }
//    WarningView()
}
