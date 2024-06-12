//
//  ShowHideToggle.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

struct ShowHideToggle<Label: View>: View {
    
    @Binding var show: Bool
    @ViewBuilder let label: () -> Label
    
    var body: some View {
        Toggle(isOn: $show) {
            label().allowsHitTesting(false)
        }
    }
}

extension ShowHideToggle {
    
    init(label: String, show: Binding<Bool>) where Label == Text {
        self.init(show: show) {
            Text(label)
        }
    }
}
