//
//  Binding.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import SwiftUI

extension Binding where Value: OptionSet, Value.Element == Value {
    
    func bind(_ options: Value, animate: Bool = false) -> Binding<Bool> {
        return .init {
            wrappedValue.contains(options)
        } set: { newValue in
            let body = {
                if newValue {
                    wrappedValue.insert(options)
                } else {
                    wrappedValue.remove(options)
                }
            }
            
            guard animate else {
                body()
                return
            }
            
            withAnimation {
                body()
            }
        }
    }
}
