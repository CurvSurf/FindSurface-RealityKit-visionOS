//
//  TypewriterView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

@MainActor
struct TypewriterView: View {
    
    let text: String
    let font: Font?
    let timeInterval: TimeInterval
    let completedHandler: () async -> Void
    
    @State private var displayedText: String = ""
    
    init(text: String,
         font: Font? = .subheadline.bold().monospaced(),
         timeInterval: TimeInterval = 0.030,
         completedHandler: @escaping () async -> Void = {}) {
        self.text = text
        self.font = font
        self.timeInterval = timeInterval
        self.completedHandler = completedHandler
    }
    
    var body: some View {
        Text(displayedText)
            .font(font)
            .task {
                await appendCharacter()
            }
    }
    
    private func appendCharacter() async {
        do {
            for char in text {
                try await Task.sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
                displayedText.append(char)
            }
        } catch {}
        await completedHandler()
    }
}
