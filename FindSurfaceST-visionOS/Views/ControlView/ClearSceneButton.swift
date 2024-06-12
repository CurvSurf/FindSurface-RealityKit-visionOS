//
//  ClearSceneButton.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

struct ClearSceneButton: View {
    
    let action: () -> Void
    
    var body: some View {
        Button("Clear Scene", role: .destructive, action: action)
            .allowsHitTesting(true)
            .accessibilityHint("Removes all shapes that you have found.")
            .accessibilityInputLabels(["Clear"])
    }
}
