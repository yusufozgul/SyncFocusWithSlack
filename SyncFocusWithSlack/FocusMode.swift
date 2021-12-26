//
//  FocusMode.swift
//  SyncFocusWithSlack
//
//  Created by Yusuf Özgül on 26.12.2021.
//

import Foundation

class FocusStateCheckFilter: ObservableObject {
    @Published var focusModes: [FocusMode] = []

    init(focusModes: [FocusMode]) {
        self.focusModes = focusModes
    }

    init() { }
}

struct FocusMode {
    var focusName: String
    var focusId: String
    var isChecked: Bool
    init(focusName: String, focusId: String, isChecked: Bool) {
        self.focusName = focusName
        self.focusId = focusId
        self.isChecked = isChecked
    }
}
