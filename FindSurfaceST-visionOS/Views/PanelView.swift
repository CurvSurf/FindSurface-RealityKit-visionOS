//
//  PanelView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

struct PanelView: View {
    
    @Environment(AppState.self) private var state
    
    var body: some View {
        HStack {
            ControlView()
            if state.showResultPanel {
                ResultView()
            }
        }
        .frame(width: state.showResultPanel ? 840 : 340,
               height: 490, alignment: .top)
        .interactiveDismissDisabled()
    }
}

import FindSurface_visionOS
#Preview {
    PanelView()
        .environment(AppState())
        .environment(FindSurface.instance)
}
