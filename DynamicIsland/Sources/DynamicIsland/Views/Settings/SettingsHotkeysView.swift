import SwiftUI

struct SettingsHotkeysView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @State private var recordingAction: String?

    private struct HotkeyAction: Identifiable {
        let id: String; let label: String; let binding: KeyPath<SettingsViewModel, HotkeyBinding>
    }

    private let actions: [HotkeyAction] = [
        .init(id: "playPause", label: "Play/Pause", binding: \.playPauseBinding),
        .init(id: "nextTrack", label: "Next Track", binding: \.nextTrackBinding),
        .init(id: "previousTrack", label: "Previous Track", binding: \.previousTrackBinding),
        .init(id: "toggleIsland", label: "Toggle Island", binding: \.toggleIslandBinding),
    ]

    var body: some View {
        Form {
            Section {
                ForEach(actions) { action in
                    HStack {
                        Text(action.label).frame(width: 120, alignment: .leading)
                        Spacer()
                        if recordingAction == action.id {
                            HStack(spacing: 4) {
                                Circle().fill(.red).frame(width: 6, height: 6)
                                Text("Recording...").foregroundStyle(.secondary)
                            }
                            .font(.caption)
                        } else {
                            Text(settings[keyPath: action.binding].displayString)
                                .font(.caption.monospaced()).foregroundStyle(.secondary)
                                .frame(minWidth: 60, alignment: .trailing)
                        }
                        Button(recordingAction == action.id ? "Recording..." : "Record") {
                            startRecording(for: action)
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(recordingAction == action.id ? Color.red : Color.accentColor)
                    }
                }
            } header: { Text("Hotkeys") } footer: {
                if recordingAction != nil {
                    Text("Press the key combination you want to use...").foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func startRecording(for action: HotkeyAction) {
        recordingAction = action.id
        HotkeyManager.shared.startRecording { [self] binding in
            switch action.id {
            case "playPause": settings.playPauseBinding = binding
            case "nextTrack": settings.nextTrackBinding = binding
            case "previousTrack": settings.previousTrackBinding = binding
            case "toggleIsland": settings.toggleIslandBinding = binding
            default: break
            }
            HotkeyManager.shared.stopRecording()
            recordingAction = nil
        }
    }
}
