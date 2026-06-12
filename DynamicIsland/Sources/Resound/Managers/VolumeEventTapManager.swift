import Cocoa
import CoreAudio
import CoreGraphics
import OSLog

let VolumeUpKeyCode: Int64 = 120
let VolumeDownKeyCode: Int64 = 121
let MuteKeyCode: Int64 = 122

@MainActor
final class VolumeEventTapManager {
    static let shared = VolumeEventTapManager()
    private let logger = Logger(subsystem: "com.resound.app", category: "VolumeTap")
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var hasPermission = false
    private var audioListenerSet = false

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    var isPermissionGranted: Bool {
        AXIsProcessTrusted()
    }

    func start() {
        guard !hasPermission else { return }

        setupAudioVolumeListener()

        if isPermissionGranted {
            hasPermission = true
            createTap()
        } else {
            logger.warning("Accessibility permission not granted — prompting")
            requestPermission()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(retryTap),
                name: NSApplication.didBecomeActiveNotification,
                object: nil
            )
        }
    }

    @objc private func retryTap() {
        guard !hasPermission else {
            NotificationCenter.default.removeObserver(self, name: NSApplication.didBecomeActiveNotification, object: nil)
            return
        }
        if isPermissionGranted {
            NotificationCenter.default.removeObserver(self, name: NSApplication.didBecomeActiveNotification, object: nil)
            hasPermission = true
            createTap()
        }
    }

    private let audioListenerCallback: AudioObjectPropertyListenerProc = { _, _, _, refcon in
        guard let refcon else { return noErr }
        let manager = Unmanaged<VolumeEventTapManager>.fromOpaque(refcon).takeUnretainedValue()
        guard let device = manager.defaultOutputDeviceID() else { return noErr }
        let volume = manager.readSystemVolume()
        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var muteAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        let result = AudioObjectGetPropertyData(device, &muteAddr, 0, nil, &size, &muted)
        let isMuted = result == noErr ? muted == 1 : false
        manager.publishVolume(volume, muted: isMuted)
        return noErr
    }

    private func setupAudioVolumeListener() {
        guard !audioListenerSet else { return }
        guard let device = defaultOutputDeviceID() else { return }

        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var mutedAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        AudioObjectAddPropertyListener(device, &volumeAddress, audioListenerCallback, selfPtr)
        AudioObjectAddPropertyListener(device, &mutedAddress, audioListenerCallback, selfPtr)
        audioListenerSet = true
    }

    private func createTap() {
        let sysDefined = CGEventMask(1) << CGEventMask(14)
        let keyDown = CGEventMask(1) << CGEventMask(CGEventType.keyDown.rawValue)
        let eventMask = sysDefined | keyDown
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        let callback: @convention(c) (CGEventTapProxy, CGEventType, CGEvent, UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let manager = Unmanaged<VolumeEventTapManager>.fromOpaque(refcon).takeUnretainedValue()

            if type == .keyDown {
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) == 1
                let step: Float = 1.0 / 16.0

                switch keyCode {
                case MuteKeyCode:
                    if !isRepeat {
                        let muted = manager.toggleMute()
                        manager.publishVolume(manager.readSystemVolume(), muted: muted)
                    }
                    return nil
                case VolumeDownKeyCode:
                    let vol = manager.readSystemVolume()
                    let newVol = max(0, vol - step)
                    manager.setSystemVolume(newVol)
                    manager.publishVolume(newVol, muted: false)
                    return nil
                case VolumeUpKeyCode:
                    let vol = manager.readSystemVolume()
                    let newVol = min(1.0, vol + step)
                    manager.setSystemVolume(newVol)
                    manager.publishVolume(newVol, muted: false)
                    return nil
                default:
                    return Unmanaged.passUnretained(event)
                }
            }

            guard type.rawValue == 14 else {
                return Unmanaged.passUnretained(event)
            }

            guard let nsEvent = NSEvent(cgEvent: event), nsEvent.subtype.rawValue == 8 else {
                return Unmanaged.passUnretained(event)
            }

            let data1 = nsEvent.data1
            let keyCode = Int((data1 & 0xFFFF0000) >> 16)
            let keyFlags = data1 & 0x0000FFFF
            let keyState = Int((keyFlags & 0xFF00) >> 8)

            guard keyState == 0xA else {
                return Unmanaged.passUnretained(event)
            }

            let step: Float = 1.0 / 16.0

            switch keyCode {
            case 0, 1:
                let vol = manager.readSystemVolume()
                let newVol: Float
                if keyCode == 0 {
                    newVol = min(1.0, vol + step)
                } else {
                    newVol = max(0, vol - step)
                }
                manager.setSystemVolume(newVol)
                manager.publishVolume(newVol, muted: false)
                return nil
            case 7:
                let muted = manager.toggleMute()
                manager.publishVolume(manager.readSystemVolume(), muted: muted)
                return nil
            default:
                return Unmanaged.passUnretained(event)
            }
        }

        tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: userInfo
        )

        guard let tap else {
            logger.error("Failed to create event tap (permission revoked?)")
            hasPermission = false
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        logger.info("Volume event tap started")
    }

    private func defaultOutputDeviceID() -> AudioDeviceID? {
        var id = AudioDeviceID()
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let result = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &id
        )
        return result == noErr ? id : nil
    }

    private func readSystemVolume() -> Float {
        guard let device = defaultOutputDeviceID() else { return 0.5 }
        var volume: Float = 0
        var size = UInt32(MemoryLayout<Float>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        let result = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &volume)
        return result == noErr ? volume : 0.5
    }

    private func setSystemVolume(_ volume: Float) {
        guard let device = defaultOutputDeviceID() else { return }
        var vol = volume
        let size = UInt32(MemoryLayout<Float>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectSetPropertyData(device, &address, 0, nil, size, &vol)
    }

    func toggleMute() -> Bool {
        guard let device = defaultOutputDeviceID() else { return false }
        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        if AudioObjectGetPropertyData(device, &address, 0, nil, &size, &muted) == noErr {
            let newMute = muted == 0 ? UInt32(1) : UInt32(0)
            var newVal = newMute
            AudioObjectSetPropertyData(device, &address, 0, nil, size, &newVal)
            return newMute == 1
        }
        return false
    }

    private func publishVolume(_ volume: Float, muted: Bool) {
        Task { @MainActor in
            VolumeOverlayState.shared.show(level: volume, muted: muted)
        }
    }
}
