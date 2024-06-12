//
//  ResultView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

struct ResultView: View {
    
    @Environment(AppState.self) private var state
    
    var body: some View {
        VStack(alignment: .leading) {
            Section {
                Text("Points: \(state.pointCount) pts.")
                    .allowsHitTesting(false)
                
                ResultMessageListView(messageItems: state.resultMessages)
                    .allowsHitTesting(false)
            } header: {
                ResultSectionHeader {
                    state.showPanels = false
                }
            }
        }
        .padding()
        .frame(width: 500, height: 490, alignment: .top)
        .background(.clear.opacity(0))
        .border(Color.white)
    }
}
