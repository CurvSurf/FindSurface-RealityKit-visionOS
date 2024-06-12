//
//  FailSign.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/20/24.
//

import Foundation
import SwiftUI

struct FailSignView: View {
    
    var body: some View {
        Text("Not found...")
            .font(.largeTitle)
        .padding()
        .background(.gray.opacity(0.3))
        .border(.white, width: 2)
    }
}
