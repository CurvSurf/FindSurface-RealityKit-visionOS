//
//  ResultMessageListView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

struct ResultMessageListView: View {
    
    let messageItems: [ResultMessage]
    
    var body: some View {
        ScrollViewReader { value in
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(messageItems, id: \.uuid) { item in
                        HStack {
                            if let lastItem = messageItems.last,
                               item == lastItem {
                                ZStack(alignment: .topLeading) {
                                    Text(item.message)
                                        .foregroundStyle(.clear)
                                    
                                    TypewriterView(text: item.message)
                                }
                                .id(item.uuid)
                            } else {
                                Text(item.message)
                                    .font(.subheadline.bold().monospaced())
                                    .frame(alignment: .leading)
                                    .id(item.uuid)
                            }
                            Spacer()
                        }
                    }
                }
                .onChange(of: messageItems.count) { _, _ in
                    withAnimation {
                        if let lastItem = messageItems.last {
                            value.scrollTo(lastItem.uuid)
                        }
                    }
                }
            }
        }
    }
}

