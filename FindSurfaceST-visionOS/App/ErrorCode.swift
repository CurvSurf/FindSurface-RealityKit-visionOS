//
//  ErrorCode.swift
//  FindSurfaceST-visionOS
//
//  Created by CurvSurf-SGKim on 6/18/24.
//

import Foundation
import ARKit

enum ErrorCode: Hashable, Codable, Error {
    
    case openImmersiveSpaceFailed
    case sessionErrorOccurred(ErrorDescriptor)
    case worldTrackingProviderStopped(ErrorDescriptor)
    case fileSaveFailed(String)
    case fileLoadFailed
    case saveFileCorrupted(String)
    case findSurfaceError(String)
    
    var description: String {
        switch self {
        case .openImmersiveSpaceFailed:     return "Failed to open the immersive space."
        case .sessionErrorOccurred:         return "The session has stopped due to an error."
        case .worldTrackingProviderStopped: return "WorldTrackingProvider has stopped due to an error."
        case .fileSaveFailed:               return "Failed to save data into a file."
        case .fileLoadFailed:               return "Failed to load data from a file."
        case .saveFileCorrupted:            return "Save file has been corrupted."
        case .findSurfaceError:             return "FindSurface failed due to an error."
        }
    }
}

struct ErrorDescriptor: Hashable, Codable {
    enum DataProvider: String, Codable {
        case worldTrackingProvider = "WorldTrackingProvider"
        case handTrackingProvider = "HandTrackingProvider"
        case imageTrackingProvider = "ImageTrackingProvider"
        case planeDetectionProvider = "PlaneDetectionProvider"
        case sceneReconstructionProvider = "SceneReconstructionProvider"
        case none = "None"
    }
    enum ErrorCode: String, Codable {
        case dataProviderNotAuthorized = "dataProviderNotAuthorized"
        case dataProviderFailedToRun = "dataProviderFailedToRun"
        case addWorldAnchorFailed = "addWorldAnchorFailed"
        case removeWorldAnchorFailed = "removeWorldAnchorFailed"
        case worldAnchorLimitReached = "worldAnchorLimitReached"
        case unknown = "Unknown"
    }
    let dataProvider: DataProvider
    let code: ErrorCode
    let description: String
    let localizedDescription: String
    let errorDescription: String?
    var recoverySuggestion: String?
    var failureReason: String?
    var helpAnchor: String?
    
    init(dataProvider: DataProvider, 
         code: ErrorCode,
         description: String,
         localizedDescription: String,
         errorDescription: String?,
         recoverySuggestion: String? = nil,
         failureReason: String? = nil,
         helpAnchor: String? = nil) {
        self.dataProvider = dataProvider
        self.code = code
        self.description = description
        self.localizedDescription = localizedDescription
        self.errorDescription = errorDescription
        self.recoverySuggestion = recoverySuggestion
        self.failureReason = failureReason
        self.helpAnchor = helpAnchor
    }
    
    var formattedDescription: String {
        """
Data Provider: \(dataProvider)
Error Code: \(code)
Description: \(description)
Localized Description: \(localizedDescription)
Error Description: \(errorDescription ?? "N/A")
Recovery Suggestion: \(recoverySuggestion ?? "N/A")
Failure Reason: \(failureReason ?? "N/A")
Help Anchor: \(helpAnchor ?? "N/A")
"""
    }
}

fileprivate extension ErrorDescriptor.DataProvider {
    init(_ dataProvider: (any DataProvider)?) {
        guard let dataProvider else {
            self = .none
            return
        }
        
        switch dataProvider {
        case is WorldTrackingProvider:          self = .worldTrackingProvider
        case is HandTrackingProvider:           self = .handTrackingProvider
        case is ImageTrackingProvider:          self = .imageTrackingProvider
        case is SceneReconstructionProvider:    self = .sceneReconstructionProvider
        case is PlaneDetectionProvider:         self = .planeDetectionProvider
        default:                                self = .none
        }
    }
}

fileprivate extension ErrorDescriptor.ErrorCode {
    init(_ errorCode: ARKitSession.Error.Code) {
        switch errorCode {
        case .dataProviderFailedToRun: self = .dataProviderFailedToRun
        case .dataProviderNotAuthorized: self = .dataProviderNotAuthorized
        @unknown default: fatalError()
        }
    }
    init(_ errorCode: WorldTrackingProvider.Error.Code) {
        switch errorCode {
        case .addWorldAnchorFailed: self = .addWorldAnchorFailed
        case .removeWorldAnchorFailed: self = .removeWorldAnchorFailed
        case .worldAnchorLimitReached: self = .worldAnchorLimitReached
        @unknown default: fatalError()
        }
    }
}

extension ErrorDescriptor {
    init(from error: ARKitSession.Error) {
        let dataProvider = DataProvider(error.dataProvider)
        let errorCode = ErrorCode(error.code)
        self.init(dataProvider: dataProvider,
                  code: errorCode,
                  description: error.description,
                  localizedDescription: error.localizedDescription,
                  errorDescription: error.errorDescription,
                  recoverySuggestion: error.recoverySuggestion,
                  failureReason: error.failureReason,
                  helpAnchor: error.helpAnchor)
    }
    init(from error: WorldTrackingProvider.Error) {
        let dataProvider = DataProvider.worldTrackingProvider
        let errorCode = ErrorCode(error.code)
        self.init(dataProvider: dataProvider,
                  code: errorCode,
                  description: error.description,
                  localizedDescription: error.localizedDescription,
                  errorDescription: error.errorDescription,
                  recoverySuggestion: error.recoverySuggestion,
                  failureReason: error.failureReason,
                  helpAnchor: error.helpAnchor)
    }
}
