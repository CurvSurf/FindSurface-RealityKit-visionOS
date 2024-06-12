//
//  SceneIDProtocol.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/17/24.
//

import Foundation
import SwiftUI

protocol SceneIDProtocol: Hashable, CaseIterable {
    var rawValue: String { get }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: any SceneIDProtocol) {
        appendInterpolation(value.rawValue)
    }
}

extension WindowGroup {
    init<ID>(sceneID: ID,
             @ViewBuilder content: () -> Content
    ) where ID: SceneIDProtocol {
        self.init(id: sceneID.rawValue, content: content)
    }
    
    init<ID>(_ title: Text,
             sceneID: ID,
             @ViewBuilder content: () -> Content
    ) where ID: SceneIDProtocol {
        self.init(title, id: sceneID.rawValue, content: content)
    }
    
    init<ID>(_ titleKey: LocalizedStringKey,
             sceneID: ID,
             @ViewBuilder content: () -> Content
    ) where ID: SceneIDProtocol {
        self.init(titleKey, id: sceneID.rawValue, content: content)
    }
    
    init<ID, S>(_ title: S,
                sceneID: ID,
                @ViewBuilder content: () -> Content
    ) where ID: SceneIDProtocol, S: StringProtocol {
        self.init(title, id: sceneID.rawValue, content: content)
    }
    
    init<ID, D, C>(sceneID: ID,
                   for type: D.Type,
                   @ViewBuilder content: @escaping (Binding<D?>) -> C
    ) where ID: SceneIDProtocol, Content == PresentedWindowContent<D, C>, D: Decodable, D: Encodable, D: Hashable, C: View {
        self.init(id: sceneID.rawValue, for: type, content: content)
    }
    
    init<ID, D, C>(_ title: Text,
                   sceneID: ID,
                   for type: D.Type,
                   @ViewBuilder content: @escaping (Binding<D?>) -> C
    ) where ID: SceneIDProtocol, Content == PresentedWindowContent<D, C>, D: Decodable, D: Encodable, D: Hashable, C: View {
        self.init(title, id: sceneID.rawValue, for: type, content: content)
    }
    
    init<ID, D, C>(_ titleKey: LocalizedStringKey,
                   sceneID: ID,
                   for type: D.Type,
                   @ViewBuilder content: @escaping (Binding<D?>) -> C
    ) where ID: SceneIDProtocol, Content == PresentedWindowContent<D, C>, D: Decodable, D: Encodable, D: Hashable, C: View {
        self.init(titleKey, id: sceneID.rawValue, for: type, content: content)
    }
    
    init<ID, S, D, C>(_ title: S,
                      sceneID: ID,
                      for type: D.Type,
                      @ViewBuilder content: @escaping (Binding<D?>) -> C
    ) where ID: SceneIDProtocol, Content == PresentedWindowContent<D, C>, S: StringProtocol, D: Decodable, D: Encodable, D: Hashable, C: View {
        self.init(title, id: sceneID.rawValue, for: type, content: content)
    }
    
    init<ID, D, C>(_ title: Text,
                   sceneID: ID,
                   for type: D.Type = D.self,
                   @ViewBuilder content: @escaping (Binding<D>) -> C,
                   defaultValue: @escaping () -> D
    ) where ID: SceneIDProtocol, Content == PresentedWindowContent<D, C>, D: Decodable, D: Encodable, D: Hashable, C: View {
        self.init(title, id: sceneID.rawValue, for: type, content: content, defaultValue: defaultValue)
    }
    
    init<ID, D, C>(_ titleKey: LocalizedStringKey,
                   sceneID: ID,
                   for type: D.Type = D.self,
                   @ViewBuilder content: @escaping (Binding<D>) -> C,
                   defaultValue: @escaping () -> D
    ) where ID: SceneIDProtocol, Content == PresentedWindowContent<D, C>, D: Decodable, D: Encodable, D: Hashable, C: View {
        self.init(titleKey, id: sceneID.rawValue, for: type, content: content, defaultValue: defaultValue)
    }
    
    init<ID, S, D, C>(_ title: S,
                      sceneID: ID,
                      for type: D.Type = D.self,
                      @ViewBuilder content: @escaping (Binding<D>) -> C,
                      defaultValue: @escaping () -> D
    ) where ID: SceneIDProtocol, Content == PresentedWindowContent<D, C>, S: StringProtocol, D: Decodable, D: Encodable, D: Hashable, C: View {
        self.init(title, id: sceneID.rawValue, for: type, content: content, defaultValue: defaultValue)
    }
}

extension ImmersiveSpace {
    
    init<ID>(sceneID: ID,
             @ImmersiveSpaceContentBuilder content: () -> Content
    ) where ID: SceneIDProtocol, Data == Never {
        self.init(id: sceneID.rawValue, content: content)
    }
    
    init<ID>(sceneID: ID,
             for type: Data.Type,
             @ImmersiveSpaceContentBuilder content: @escaping (Binding<Data?>) -> Content
    ) where ID: SceneIDProtocol {
        self.init(id: sceneID.rawValue, for: type, content: content)
    }
    
    init<ID>(sceneID: ID,
             for type: Data.Type = Data.self,
             @ImmersiveSpaceContentBuilder content: @escaping (Binding<Data>) -> Content,
             defaultValue: @escaping () -> Data
    ) where ID: SceneIDProtocol {
        self.init(id: sceneID.rawValue, for: type, content: content, defaultValue: defaultValue)
    }
    
    init<ID, V>(sceneID: ID,
                @ViewBuilder content: () -> V
    ) where ID: SceneIDProtocol, Content == ImmersiveSpaceViewContent<V>, Data == Never, V: View {
        self.init(id: sceneID.rawValue, content: content)
    }
    
    init<ID, V>(sceneID: ID,
                for type: Data.Type,
                @ViewBuilder content: @escaping (Binding<Data?>) -> V
    ) where ID: SceneIDProtocol, Content == ImmersiveSpaceViewContent<V>, V: View {
        self.init(id: sceneID.rawValue, for: type, content: content)
    }
    
    init<ID, V>(sceneID: ID,
                for type: Data.Type = Data.self,
                @ViewBuilder content: @escaping (Binding<Data>) -> V,
                defaultValue: @escaping () -> Data
    ) where ID: SceneIDProtocol, Content == ImmersiveSpaceViewContent<V>, V: View {
        self.init(id: sceneID.rawValue, for: type, content: content, defaultValue: defaultValue)
    }
}

extension OpenWindowAction {
    
    func callAsFunction<ID>(sceneID: ID) where ID: SceneIDProtocol {
        self.callAsFunction(id: sceneID.rawValue)
        
    }
    
    func callAsFunction<ID, D>(sceneID: ID,
                               value: D
    ) where ID: SceneIDProtocol, D: Decodable, D: Encodable, D: Hashable {
        self.callAsFunction(id: sceneID.rawValue, value: value)
    }
}

extension DismissWindowAction {
    
    func callAsFunction<ID>(sceneID: ID) where ID: SceneIDProtocol {
        self.callAsFunction(id: sceneID.rawValue)
    }
    
    func callAsFunction<ID, D>(sceneID: ID,
                               value: D
    ) where ID: SceneIDProtocol, D: Decodable, D: Encodable, D: Hashable {
        self.callAsFunction(id: sceneID.rawValue, value: value)
    }
}

extension OpenImmersiveSpaceAction {
    
    func callAsFunction<ID>(sceneID: ID) async -> Result where ID: SceneIDProtocol {
        await self.callAsFunction(id: sceneID.rawValue)
    }
    
    func callAsFunction<ID, D>(sceneID: ID,
                               value: D
    ) async -> Result where ID: SceneIDProtocol, D: Decodable, D: Encodable, D: Hashable {
        await self.callAsFunction(id: sceneID.rawValue, value: value)
    }
}

