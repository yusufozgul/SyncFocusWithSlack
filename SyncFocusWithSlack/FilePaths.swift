//
//  FilePaths.swift
//  SyncFocusWithSlack
//
//  Created by Yusuf Özgül on 26.12.2021.
//

import Foundation

enum FilePaths {
    case assertions
    case modeConfigurations
    
    var filePath: URL? {
        let currentState = try? FileManager.default.url(
            for: .allLibrariesDirectory,
               in: .userDomainMask,
               appropriateFor: nil,
               create: false
        )
        let dndPath = currentState?.appendingPathComponent("DoNotDisturb/DB/")
        
        switch self {
        case .assertions:
            return dndPath?.appendingPathComponent("Assertions.json")
        case .modeConfigurations:
            return dndPath?.appendingPathComponent("ModeConfigurations.json")
        }
    }
}
