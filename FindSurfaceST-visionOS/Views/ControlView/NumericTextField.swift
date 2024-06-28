//
//  NumericTextField.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import SwiftUI

struct NumericTextField<Label: View>: View {

    @Binding var value: Float
    let minValue: Float?
    let maxValue: Float?
    @ViewBuilder let label: () -> Label
    
    init(value: Binding<Float>,
         minValue: Float? = nil,
         maxValue: Float? = nil,
         @ViewBuilder label: @escaping () -> Label) {
        self._value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.label = label
    }
    
    var body: some View {
        HStack {
            label().lineLimit(1)
                .minimumScaleFactor(0.5).allowsHitTesting(false)
                .accessibilityHidden(true)
            TextField("", value: $value.convertFromMeterToCentimeter(),
                      formatter: .centimeterWithMillimeterFraction) { finished in
                if finished {
                    if let minValue {
                        value = max(value, minValue)
                    }
                    if let maxValue {
                        value = min(value, maxValue)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.decimalPad)
            .allowsHitTesting(true)
            .padding(.vertical, -4)
            
        }
    }
}

extension NumericTextField {
    init(label: String, value: Binding<Float>, minValue: Float? = nil, maxValue: Float? = nil) where Label == Text {
        self.init(value: value, minValue: minValue, maxValue: maxValue) {
            Text(label)
        }
    }
}

fileprivate extension Binding where Value: BinaryFloatingPoint {
    func convertFromMeterToCentimeter() -> Binding<Value> {
        Binding<Value> {
            wrappedValue * 100.0
        } set: { newValue in
            wrappedValue = newValue * 0.01
        }
    }
}

fileprivate extension Formatter {
    static var centimeterWithMillimeterFraction: Formatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }
}
