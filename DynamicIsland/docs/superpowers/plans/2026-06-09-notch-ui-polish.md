# Notch UI Polish — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reskin the dynamic island widget to look like the M3 MacBook notch — pure black, flush top, flat-top/rounded-bottom shape, with a subtle waveform on the collapsed pill.

**Architecture:** Purely visual changes to 4 SwiftUI/Cocoa files. No logic or data flow changes. The ExistingPanel background switches from `.ultraThinMaterial` to `.black`, the shape changes from `Capsule`/`RoundedRectangle` to `UnevenRoundedRectangle`, and the pill gains an animated waveform on the right side when playing.

**Tech Stack:** SwiftUI, Swift 6, macOS native APIs

---

### Task 1: WindowManager — Flush top position

**Files:**
- Modify: `Sources/DynamicIsland/WindowManager.swift:43-45`

- [ ] **Step 1: Remove the 8px top gap**

Change `positionWindow` to use `screen.maxY - height` instead of `screen.maxY - height - 8`:

```swift
private func positionWindow(_ window: NSWindow) {
    guard let screen = NSScreen.main?.visibleFrame else { return }
    let width: CGFloat = 340
    let y = screen.maxY - collapsedHeight
    let x = screen.midX - width / 2
    window.setFrame(NSRect(x: x, y: y, width: width, height: collapsedHeight), display: true)
    window.invalidateShadow()
}
```

- [ ] **Step 2: Do the same in `toggleExpanded`**

```swift
let y = screen.maxY - height
```

- [ ] **Step 3: Build and verify**

Run: `swift build`

Expected: Build succeeds. Window appears flush with the top of the screen.

---

### Task 2: PillView — Notch shape, pure black, waveform

**Files:**
- Modify: `Sources/DynamicIsland/Views/PillView.swift`

- [ ] **Step 1: Replace the Capsule background with UnevenRoundedRectangle + pure black**

```swift
.background(
    UnevenRoundedRectangle(
        cornerRadii: .init(
            bottomLeading: 14,
            bottomTrailing: 14
        ),
        style: .continuous
    )
    .fill(.black)
)
```

Replace the existing `.background(Capsule().fill(.ultraThinMaterial))`.

- [ ] **Step 2: Remove the border overlay**

Delete the entire `.overlay(Capsule().stroke(...))` block.

- [ ] **Step 3: Add animated waveform on the right side**

After the `trackLabel` in the `HStack`, add:

```swift
if isPlaying {
    waveform
        .opacity(0.6)
        .transition(.opacity)
}
```

And define the waveform view using `PhaseAnimator`:

```swift
@ViewBuilder
private var waveform: some View {
    PhaseAnimator([0, 1, 2, 1]) { phase in
        HStack(spacing: 3) {
            Capsule()
                .fill(.white)
                .frame(width: 3, height: 8 + barHeight(index: 0, phase: phase))
            Capsule()
                .fill(.white)
                .frame(width: 3, height: 8 + barHeight(index: 1, phase: phase))
            Capsule()
                .fill(.white)
                .frame(width: 3, height: 8 + barHeight(index: 2, phase: phase))
        }
    } animation: { phase in
        .easeInOut(duration: 0.6)
    }
}

private func barHeight(index: Int, phase: Int) -> CGFloat {
    let heights: [[CGFloat]] = [
        [0, 6, 2],  // bar 0: peaks at phase 1
        [6, 0, 4],  // bar 1: peaks at phase 0
        [2, 4, 0],  // bar 2: peaks between phase 0-1
    ]
    return heights[index][phase % heights[index].count]
}
```

- [ ] **Step 4: Build and verify**

Run: `swift build`

Expected: Build succeeds.

---

### Task 3: ExpandedPanel — Notch shape, pure black

**Files:**
- Modify: `Sources/DynamicIsland/Views/ExpandedPanel.swift`

- [ ] **Step 1: Replace the RoundedRectangle background with UnevenRoundedRectangle + pure black**

```swift
.background(
    UnevenRoundedRectangle(
        cornerRadii: .init(
            bottomLeading: 14,
            bottomTrailing: 14
        ),
        style: .continuous
    )
    .fill(.black)
)
```

Replace the existing `.background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))`.

- [ ] **Step 2: Remove the border overlay**

Delete the `.overlay(RoundedRectangle(...).stroke(...))` block.

- [ ] **Step 3: Build and verify**

Run: `swift build`

Expected: Build succeeds.

---

### Task 4: ContentView — Unify background for seamless pill+panel

**Files:**
- Modify: `Sources/DynamicIsland/ContentView.swift`

- [ ] **Step 1: Add single notch-shaped background to the outer VStack**

```swift
VStack(spacing: 0) {
    pillView
        .zIndex(1)
    if isExpanded {
        expandedPanel
            .transition(.identity)
            .offset(y: -6)
    }
}
.frame(width: 340)
.background(
    UnevenRoundedRectangle(
        cornerRadii: .init(
            bottomLeading: 14,
            bottomTrailing: 14
        ),
        style: .continuous
    )
    .fill(.black)
)
```

This replaces the individual backgrounds in PillView and ExpandedPanel — make sure those are removed to avoid double backgrounds.

- [ ] **Step 2: Remove the individual backgrounds from PillView and ExpandedPanel**

In `PillView.swift`, the `.background(Capsule().fill(...))` becomes just `.background(ClearColor())` or is removed entirely.

In `ExpandedPanel.swift`, the `.background(RoundedRectangle().fill(...))` is removed since the VStack background handles it.

- [ ] **Step 3: Build and verify**

Run: `swift build`

Expected: Build succeeds.

---

### Verification

- [ ] `swift build` succeeds with no warnings
- [ ] Window appears flush at the top of the screen (no gap above the pill)
- [ ] Background is pure black (#000), not material
- [ ] Collapsed pill has flat top edge and rounded bottom corners
- [ ] Waveform appears on the right of the collapsed pill when playing
- [ ] Waveform fades when music is paused
- [ ] Expanded panel has seamless black background (no visual seam with pill)
- [ ] Expand/collapse animation works smoothly
- [ ] Hover effect still works on the pill
