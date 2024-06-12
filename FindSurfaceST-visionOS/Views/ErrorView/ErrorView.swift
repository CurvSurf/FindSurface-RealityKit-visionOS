//
//  ErrorView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

struct ErrorView: View {
    
    let errorCode: ErrorCode
    
    var body: some View {
        VStack {
            Text("⚠️ Error occurred ⚠️")
                .font(.title)
                
            Divider()
                .padding(.vertical, 10)
            ErrorDetailView(errorCode: errorCode)
                
            Divider()
                .padding(.vertical, 10)
            
            RestartGuideView()
        }
        .padding()
        .frame(width: 450)
    }
}
