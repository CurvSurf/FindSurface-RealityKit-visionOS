//
//  PendingResultView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 7/5/24.
//

import Foundation
import SwiftUI

import FindSurface_visionOS

struct PendingResultView: View {
    
    let key: UUID
    let pendingResult: AppState.PendingResult
    @Environment(AppState.self) private var state
    
    var body: some View {
        @Bindable var state = state
        VStack {
            Text("Suggestion")
                .font(.title)
                .padding(.bottom)
            
            Text("FindSurface has detected \(pendingResult.foundFeature) instead of \(pendingResult.targetFeature).")
                .font(.subheadline)
            Text("Do you want to keep it?")
            
            HStack {
                Button("Keep") {
                    Task {
                        state.pendingResults.removeValue(forKey: key)
                        try? await state.process(pendingResult.result)
                        state.attachmentEntities.removeValue(forKey: key)?.removeFromParent()
                        // TODO: make it handle WorldTrackingProvider.Error
                        //       What state.process(_:) can throw is
                        //       an exception saying that `WorldTrackingProvider` failed to add world anchor.
                        //       We don't know why it happens and what to do.
                        //       Also there is not much information about it in the documentation.
                        //       So we don't do anything about it until we figure out
                        //        what causes it and what we can do not to make it happen.
                    }
                }
                
                Button("Discard", role: .destructive) {
                    Task {
                        state.pendingResults.removeValue(forKey: key)
                        state.attachmentEntities.removeValue(forKey: key)?.removeFromParent()
                        let rmsError: Float = switch pendingResult.result {
                        case let .foundCylinder(_, _, rmsError): rmsError
                        case let .foundSphere(_, _, rmsError): rmsError
                        default: 0
                        }
                        state.resultMessages.append(.init("Failed: \(rmsError)"))
                        await state.showFailSign(at: pendingResult.dialogLocation)
                    }
                }
            }
        }
        .padding()
        .glassBackgroundEffect()
    }
}

fileprivate extension String.StringInterpolation {
    mutating func appendInterpolation(_ feature: FeatureType) {
        switch feature {
        case .plane: appendLiteral("plane")
        case .sphere: appendLiteral("sphere")
        case .cylinder: appendLiteral("cylinder")
        case .cone: appendLiteral("cone")
        case .torus: appendLiteral("torus")
        case .any: appendLiteral("any shape")
        }
        
    }
}
