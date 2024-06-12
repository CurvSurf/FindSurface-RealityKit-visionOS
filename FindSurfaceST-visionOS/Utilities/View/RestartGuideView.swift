//
//  RestartGuideView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import SwiftUI

struct RestartGuideView: View {
    
    @State private var showDetails: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Please restart the app after closing it completely.")
                    .font(.subheadline)
                    .fixedSize(horizontal: true, vertical: true)
                
                HelpButton(showDetails: $showDetails)
            }
            .popover(isPresented: $showDetails, 
                     arrowEdge: .top) {
                RestartGuidePopover(showDetails: $showDetails)
            }
        }
    }
}

fileprivate struct HelpButton: View {
    
    @Binding var showDetails: Bool
    
    var body: some View {
        Button {
            withAnimation {
                showDetails = true
            }
        } label: {
            Image(systemName: "questionmark.circle")
                .imageScale(.large)
                .aspectRatio(contentMode: .fit)
        }
        .clipShape(.circle)
//        .disabled(showDetails)
    }
}

fileprivate struct RestartGuidePopover: View {
    
    @Binding var showDetails: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "questionmark.circle")
                    .imageScale(.large)
                Text("How to close the app completely")
                    .font(.title)
            }
            Divider()
            HStack(spacing: 10) {
                Image(systemName: "digitalcrown.horizontal.press")
                Image(systemName: "plus")
                Image(systemName: "button.horizontal.top.press")
                Text("(3 sec.)")
                    .font(.subheadline)
            }
            
            Text("You can fully close it by pressing and holding the top button and the digital crown simultaneously for 3 seconds to bring up the menu.")
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 350)
            
            Button("Dismiss", role: .cancel) {
                withAnimation {
                    showDetails = false
                }
            }
        }
        .padding()
    }
}
