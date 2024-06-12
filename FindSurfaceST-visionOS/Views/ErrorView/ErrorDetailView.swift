//
//  ErrorDetailView.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

struct ErrorDetailView: View {
    
    let errorCode: ErrorCode
    
    var body: some View {
        VStack {
            Text(errorCode.description.decomposedStringWithCanonicalMapping)
                .font(.body)
                
            let descriptor: ErrorDescriptor? = switch errorCode {
            case let .sessionErrorOccurred(descriptor):         descriptor
            case let .worldTrackingProviderStopped(descriptor): descriptor
            case let .fileSaveFailed(reason):                   .init(dataProvider: .none, code: .unknown, description: reason, localizedDescription: "", errorDescription: nil)
            case let .findSurfaceError(reason):                 .init(dataProvider: .none, code: .unknown, description: reason, localizedDescription: "", errorDescription: nil)
            case let .saveFileCorrupted(reason):                .init(dataProvider: .none, code: .unknown, description: reason, localizedDescription: "", errorDescription: nil)
            default:                                            nil
            }
            
            if let descriptor {
                ScrollView {
                    TextField("Details",
                              text: .constant(descriptor.formattedDescription),
                              axis: .vertical)
                    .font(.subheadline.monospaced())
                    .multilineTextAlignment(.leading)
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
