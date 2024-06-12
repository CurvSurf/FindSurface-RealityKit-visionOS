//
//  ControlSectionHeader.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

struct ControlSectionHeader: View {
    
    @Binding var isExpanded: Bool
    
    var body: some View {
        HStack {
            Text("Controls")
                .font(.title)
            
            Spacer()
            
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                // sidebar.left
                Image(systemName: isExpanded ? "list.bullet.rectangle.portrait" : "sidebar.left")
            }
        }
    }
}
