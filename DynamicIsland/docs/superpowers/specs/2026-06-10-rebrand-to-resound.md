# Rebrand: DynamicIsland → Resound

## Overview
Rename the project from "DynamicIsland" to "Resound" across all source files, build configuration, and file system layout.

## Changes

### Package.swift
- `name: "DynamicIsland"` → `name: "Resound"`
- Target `name: "DynamicIsland"` → `name: "Resound"`
- Exclude path unchanged (will be `Sources/Resound/Info.plist` after directory rename)

### Source directory
- Rename `Sources/DynamicIsland/` → `Sources/Resound/`

### Info.plist
- `CFBundleExecutable`: `DynamicIsland` → `Resound`
- `CFBundleName`: `DynamicIsland` → `Resound`
- `CFBundleIdentifier`: `com.dynamicisland.app` → `com.resound.app`

### DynamicIslandApp.swift
- `struct DynamicIslandApp` → `struct ResoundApp`

### Makefile
- `.build/debug/DynamicIsland` → `.build/debug/Resound`
- `.build/release/DynamicIsland` → `.build/release/Resound`
- `DynamicIsland.app` → `Resound.app`
- `Sources/DynamicIsland/Info.plist` → `Sources/Resound/Info.plist`

## Non-Goals
- App icon — defer to a future branding pass
- Menu bar icon — stays as music note for now
- Visual/UI text changes (window titles, labels) — only bundle metadata changes
