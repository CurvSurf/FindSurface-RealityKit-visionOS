//
//  ImageButtonPicker.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import SwiftUI
import AVKit

enum ImageName {
    case systemName(String)
    case imageName(String)
}

protocol ImageButtonPickerItem: Hashable {
    associatedtype ImageForegroundStyle: ShapeStyle
    associatedtype ButtonBackground: View
    var imageName: ImageName { get }
    var imageForegroundStyle: ImageForegroundStyle { get }
    var buttonBackground: ButtonBackground { get }
    var accessibilityInputLabels: [String] { get }
}

fileprivate struct _PreferenceData<Item: ImageButtonPickerItem> {
    let item: Item
    let bounds: Anchor<CGRect>
}

fileprivate struct _PreferenceKey<Item: ImageButtonPickerItem>: PreferenceKey {
    typealias Value = [_PreferenceData<Item>]
    static var defaultValue: Value { [] }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue())
    }
}

fileprivate struct ImageButton<Item: ImageButtonPickerItem>: View {
    
    let item: Item
    @Binding var selectedItem: Item
    let accessibilityInputLabels: [String]
    
    init(item: Item, selectedItem: Binding<Item>, accessibilityInputLabels: [String] = []) {
        self.item = item
        self._selectedItem = selectedItem
        self.accessibilityInputLabels = accessibilityInputLabels
    }
    
    @ViewBuilder private var button: some View {
        let selected = selectedItem == item
        Button {
            withAnimation {
                selectedItem = item
            }
        } label: {
            switch item.imageName {
            case let .imageName(name):
                Image(name)
                    .font(selected ? .title2.weight(.bold) : .body)
                    .imageScale(.large)
                    .foregroundStyle(item.imageForegroundStyle)
            case let .systemName(name):
                Image(systemName: name)
                    .font(selected ? .title2.weight(.bold) : .body)
                    .imageScale(.large)
                    .foregroundStyle(item.imageForegroundStyle)
            }
        }
        .buttonStyle(.plain)
        .frame(width: 48, height: 48)
        .background(item.buttonBackground.opacity(selected ? 1.0 : 0.5))
        .clipShape(.rect(cornerRadius: 8))
        .anchorPreference(key: _PreferenceKey<Item>.self, value: .bounds) { anchor in
            [_PreferenceData(item: item, bounds: anchor)]
        }
    }
    
    var body: some View {
        
        if accessibilityInputLabels.isEmpty {
            button
        } else {
            button
                .accessibilityInputLabels(accessibilityInputLabels)
        }
    }
}

struct ImageButtonPicker<Item: ImageButtonPickerItem>: View {

    let items: [Item]
    @Binding var selectedItem: Item
    
    var body: some View {
        HStack {
            ForEach(items, id: \.self) { item in
                ImageButton(item: item, selectedItem: $selectedItem, accessibilityInputLabels: item.accessibilityInputLabels)
            }
        }
        .overlayPreferenceValue(_PreferenceKey<Item>.self) { preferences in
            GeometryReader { geometry in
                createBorder(geometry, preferences)
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity,
                           alignment: .topLeading)
            }
        }
    }
    
    private func createBorder(_ geometry: GeometryProxy, _ preferences: [_PreferenceData<Item>]) -> some View {
        let p = preferences.first(where: { $0.item == selectedItem })
        
        let bounds: CGRect = if let p {
            geometry[p.bounds]
        } else {
            .zero
        }
        
        return RoundedRectangle(cornerRadius: 8)
            .stroke(lineWidth: 3)
            .foregroundColor(.white)
            .frame(width: bounds.size.width, height: bounds.size.height)
            .fixedSize()
            .offset(x: bounds.minX, y: bounds.minY)
            .animation(.easeInOut(duration: 0.2), value: selectedItem)
    }
}

extension ImageButtonPicker {
    init(selectedItem: Binding<Item>) where Item: CaseIterable, Item.AllCases == Array<Item> {
        self.init(items: Item.allCases, selectedItem: selectedItem)
    }
}

enum PreviewItem: CaseIterable {
    case any
    case plane
    case sphere
    case cylinder
    case cone
    case torus
}

extension PreviewItem: ImageButtonPickerItem {
    var imageName: ImageName {
        switch self {
        case .any: return .systemName("questionmark")
        case .plane: return .systemName("square")
        case .sphere: return .systemName("basketball")
        case .cylinder: return .systemName("cylinder")
        case .cone: return .systemName("cone")
        case .torus: return .systemName("torus")
        }
    }
    
    var imageForegroundStyle: some ShapeStyle { Color.black }
    var buttonBackground: some View {
        switch self {
        case .any: return Color.gray
        case .plane: return Color.red
        case .sphere: return Color.green
        case .cylinder: return Color.purple
        case .cone: return Color.cyan
        case .torus: return Color.yellow
        }
    }
    
    var accessibilityInputLabels: [String] {
        return []
    }
}

fileprivate struct PreviewView: View {
    @State private var selectedItem: PreviewItem = .any
    var body: some View {
        ImageButtonPicker(selectedItem: $selectedItem)
            .padding()
            .border(.white, width: 2)
    }
}

#Preview {
    PreviewView()
}
