//
//  ResultSectionHeader.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

struct ResultSectionHeader: View {
    
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            Text("Results")
                .font(.title)
            
            Spacer()
            
            Button(action: action) {
                Image(systemName: "xmark")
            }
        }
    }
}
