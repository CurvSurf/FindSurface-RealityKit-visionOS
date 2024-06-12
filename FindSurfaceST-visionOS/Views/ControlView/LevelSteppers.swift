//
//  LevelSteppers.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

import FindSurface_visionOS

fileprivate struct LevelStepper<Label: View>: View {
    
    @Binding var level: SearchLevel
    @ViewBuilder let label: (SearchLevel) -> Label
    
    var body: some View {
        Stepper(value: $level.rawValue, in: 0...10) {
            label(level).allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .allowsHitTesting(true)
    }
}

fileprivate extension Binding where Value == SearchLevel {
    
    var rawValue: Binding<Int> {
        Binding<Int> {
            wrappedValue.rawValue
        } set: { newValue in
            wrappedValue = .init(rawValue: newValue)!
        }
    }
}

fileprivate extension String.StringInterpolation {
    
    mutating func appendInterpolation(_ level: SearchLevel) {
        let literal = switch level {
        case .off:  "off"
        case .lv1:  "Lv.1 (moderate)"
        case .lv2:  "Lv.2"
        case .lv3:  "Lv.3"
        case .lv4:  "Lv.4"
        case .lv5:  "Lv.5 (default)"
        case .lv6:  "Lv.6"
        case .lv7:  "Lv.7"
        case .lv8:  "Lv.8"
        case .lv9:  "Lv.9"
        case .lv10:  "Lv.10 (radical)"
        }
        appendLiteral(literal)
    }
}

struct LateralExtensionStepper: View {
    
    @Binding var level: SearchLevel
    
    var body: some View {
        LevelStepper(level: $level) { level in
            Text("Lat. Ext.: \(level)")
        }
    }
}

struct RadialExpansionStepper: View {
    
    @Binding var level: SearchLevel
    
    var body: some View {
        LevelStepper(level: $level) { level in
            Text("Rad. Exp.: \(level)")
        }
    }
}
