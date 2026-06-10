# Media-Remote Now Playing Detection

**Date:** 2026-06-10

## Problem

`NowPlayingService` only detects playback from Spotify and Apple Music via AppleScript. Browsers (Safari, Chrome, Firefox) playing YouTube, Spotify Web, etc. are invisible.

## Solution

Use the private **MediaRemote** framework — the same system API that powers the macOS Control Center "Now Playing" widget. It reports playback from any app that registers with the system, including all major browsers.

## Architecture

- **New:** `Services/MediaRemoteProvider.swift` — loads the framework via `dlopen`, registers now-playing callbacks, converts results to `NowPlayingInfo`
- **Modify:** `Services/NowPlayingService.swift` — add MediaRemote as a second source alongside AppleScript
- The two sources merge: MediaRemote for detection, AppleScript for high-res Spotify artwork override

## MediaRemoteProvider

- Loads `/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote` via `dlopen`
- Registers for `kMRMediaRemoteNowPlayingInfoDidChangeNotification`
- On change, calls `MRMediaRemoteRequestNowPlayingInfo` which returns a `CFDictionary` with title, artist, album, duration, elapsed, playback rate, artwork data
- Maps the dictionary keys to `NowPlayingInfo`
- If the source app is Spotify, also triggers AppleScript poll for higher-res artwork

## Integration

- `NowPlayingService.startMonitoring()` also starts `MediaRemoteProvider`
- Both providers publish to the same `PassthroughSubject<NowPlayingInfo, Never>`
- `NowPlayingViewModel` already consumes this — no changes needed

## Entitlements

- Requires `com.apple.security.device.media-controls` entitlement (for MediaRemote access)
- Release builds need the entitlement in the .app bundle
