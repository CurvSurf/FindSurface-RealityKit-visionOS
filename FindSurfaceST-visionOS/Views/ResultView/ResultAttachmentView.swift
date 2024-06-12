//
//  ResultAttachmentView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

struct ResultAttachmentView: View {
    
    @Environment(AppState.self) private var state
    
    let id: UUID
    let messageItem: ResultMessage
    
    var body: some View {
        VStack(alignment: .leading) {
            let content = messageItem.message
            ZStack(alignment: .leading) {
                Text(content)
                    .font(.largeTitle)
                    .foregroundStyle(.clear)
                
                TypewriterView(text: content, font: .largeTitle)
            }
        }
        .padding()
        .background(.gray.opacity(0.3))
        .border(.white, width: 2)
        .overlay(alignment: .topTrailing) {
            Button {
                Task {
                    await state.removeAnchor(id: id)
                }
            } label: {
                Image(systemName: "trash")
            }
            .glassBackgroundEffect()
            .offset(x: 16, y: -16)
            .opacity(0.5)
        }
    }
}
