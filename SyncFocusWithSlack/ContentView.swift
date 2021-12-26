//
//  ContentView.swift
//  SyncFocusWithSlack
//
//  Created by Yusuf Özgül on 26.12.2021.
//

import SwiftUI

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

var currentSelectedFocus: String? = nil

struct ContentView: View {
    @ObservedObject private var focusModesCheckStatus: FocusStateCheckFilter = .init()

    init() {
        let modes = fetchAllFocusStates()
        focusModesCheckStatus = .init(focusModes: modes)
        startTimer()
    }

    var body: some View {
        VStack {
            Text("Sync Focus With Slack")
                .font(.title2)
                .padding()

            List(focusModesCheckStatus.focusModes.indices, id: \.self) { focusIndex in
                Toggle(isOn: $focusModesCheckStatus.focusModes[focusIndex].isChecked) {
                    Text(focusModesCheckStatus.focusModes[focusIndex].focusName)
                }
                .toggleStyle(.checkbox)
            }
            .padding()

            Button("Save") {
                saveModes()
            }
            .padding()
        }
    }

    func saveModes() {
        for mode in focusModesCheckStatus.focusModes {
            UserDefaults.standard.set(mode.isChecked, forKey: mode.focusId)
        }
    }

    func fetchAllFocusStates() -> [FocusMode] {
        let currentState = try? FileManager.default.url(
            for: .allLibrariesDirectory,
               in: .userDomainMask,
               appropriateFor: nil,
               create: false
        )
        let dndPath = currentState?.appendingPathComponent("DoNotDisturb/DB/")
        let modes = dndPath?.appendingPathComponent("ModeConfigurations.json")
        let focusModesDictionary =  (try? JSONDecoder().decode(ModeConfig.self, from: Data(contentsOf: modes!)))?.data.first?.modeConfigurations ?? [:]

        var focusModes: [FocusMode] = []
        for (key, value) in focusModesDictionary {
            focusModes.append(.init(focusName: value.mode.name,
                                    focusId: key,
                                    isChecked: UserDefaults.standard.bool(forKey: key)))
        }
        return focusModes
    }

    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            self.readAndSetIfNecessary()
        }
    }

    func readAndSetIfNecessary() {
        let currentState = try? FileManager.default.url(
            for: .allLibrariesDirectory,
               in: .userDomainMask,
               appropriateFor: nil,
               create: false
        )
        let dndPath = currentState?.appendingPathComponent("DoNotDisturb/DB/")
        let assertions = dndPath?.appendingPathComponent("Assertions.json")
        let modes = dndPath?.appendingPathComponent("ModeConfigurations.json")

        let activeID = (try? JSONDecoder().decode(AssertionModel.self, from: Data(contentsOf: assertions!)))?.data.first?.storeAssertionRecords.first?.assertionDetails.assertionDetailsModeIdentifier
        let activeName = (try? JSONDecoder().decode(ModeConfig.self, from: Data(contentsOf: modes!)))?.data.first?.modeConfigurations[activeID ?? ""]?.mode.name

        if activeName == nil && currentSelectedFocus == nil {
            return
        }

        if activeName == nil && currentSelectedFocus != nil {
            //setStatus(status: "")
            currentSelectedFocus = nil
            return
        }

        if activeName == currentSelectedFocus {
            return
        }

        currentSelectedFocus = activeName

        let selectedFocusModes = focusModesCheckStatus.focusModes.filter(\.isChecked)

        if let mode = selectedFocusModes.first(where: { $0.focusName == activeName }) {
            setStatus(status: mode.focusName)
        }
    }

    func setStatus(status: String) {
        let setStatus = """
tell application "Slack"
    activate
    tell application "System Events"
        delay 1
        keystroke "Y" using {shift down, command down}
        delay 0.5
        keystroke "%@"
        delay 0.5
        key code 36
    end tell
end tell
"""
        let clearStatus = """
tell application "Slack"
        activate
        tell application "System Events"
            key code 44
            delay 0.5
            keystroke "Clear your status"
            delay 0.5
            key code 36
        end tell
    end tell

"""

        let scriptText = status.isEmpty ? clearStatus : String(format: setStatus, arguments: [status])
        if let script = NSAppleScript(source: scriptText) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let err = error {
                print(err)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

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
