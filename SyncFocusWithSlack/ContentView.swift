//
//  ContentView.swift
//  SyncFocusWithSlack
//
//  Created by Yusuf Özgül on 26.12.2021.
//

import SwiftUI

var currentSelectedFocus: String? = nil

struct ContentView: View {
    @ObservedObject private var focusModesCheckStatus: FocusStateCheckFilter = .init()
    let jsonDecoder = JSONDecoder()

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
        guard let modeConfigurationsUrl = FilePaths.modeConfigurations.filePath,
              let modeConfiguration = try? jsonDecoder.decode(ModeConfig.self, from: Data(contentsOf: modeConfigurationsUrl)),
              let focusModesDictionary = modeConfiguration.data.first?.modeConfigurations
        else { return [] }
        
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
        guard let modeConfigurationsUrl = FilePaths.modeConfigurations.filePath,
              let assertionsUrl = FilePaths.assertions.filePath,
              let modeConfiguration = try? jsonDecoder.decode(ModeConfig.self, from: Data(contentsOf: modeConfigurationsUrl)),
              let assertions = try? jsonDecoder.decode(AssertionModel.self, from: Data(contentsOf: assertionsUrl)),
              let focusModesDictionary = modeConfiguration.data.first?.modeConfigurations,
              let activeFocusId = assertions.data.first?.storeAssertionRecords.first?.assertionDetails.assertionDetailsModeIdentifier,
              let activeFocusName = focusModesDictionary[activeFocusId]?.mode.name
        else {
            currentSelectedFocus = nil
            return
        }

        if activeFocusName == currentSelectedFocus {
            return
        }

        currentSelectedFocus = activeFocusName
        let selectedFocusModes = focusModesCheckStatus.focusModes.filter(\.isChecked)

        if let mode = selectedFocusModes.first(where: { $0.focusName == activeFocusName }) {
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
