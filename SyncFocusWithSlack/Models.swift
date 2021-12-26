//
//  Models.swift
//  SyncFocusWithSlack
//
//  Created by Yusuf Özgül on 26.12.2021.
//

import Foundation

// MARK: - AssertionModel
struct AssertionModel: Codable {
    let data: [Assertion]

    struct Assertion: Codable {
        let storeAssertionRecords: [StoreAssertionRecord]
    }

    struct StoreAssertionRecord: Codable {
        let assertionDetails: StoreAssertionRecordAssertionDetails
    }

    struct StoreAssertionRecordAssertionDetails: Codable {
        let assertionDetailsModeIdentifier: String
    }
}

// MARK: - ModeConfig
struct ModeConfig: Codable {
    let data: [Config]

    struct Config: Codable {
        let modeConfigurations: [String : COMApple]
    }

    struct COMApple: Codable {
        let mode: Mode
    }

    struct Mode: Codable {
        let name: String
    }
}
