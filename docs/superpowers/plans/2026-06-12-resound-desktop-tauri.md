# Resound Desktop (Tauri + Vue 3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a cross-platform Windows/Linux desktop app matching the Resound macOS feature set — floating pill UI, music controls, artwork, volume OSD.

**Architecture:** Tauri v2 (Rust backend) + Vue 3 (frontend) in `resound-desktop/` directory. Rust handles all platform-specific media integration (Windows.Media.Control, MPRIS D-Bus), system tray, and volume control. Vue 3 renders the floating overlay with dark aesthetic. IPC bridge connects frontend to backend.

**Tech Stack:** Tauri v2, Rust, Vue 3 + Vite + TypeScript, `windows` crate (Win), `zbus` crate (Linux MPRIS)

---

### Task 1: Scaffold Tauri + Vue 3 Project

**Files:**
- Create: `resound-desktop/package.json`
- Create: `resound-desktop/vite.config.ts`
- Create: `resound-desktop/tsconfig.json`
- Create: `resound-desktop/tsconfig.node.json`
- Create: `resound-desktop/index.html`
- Create: `resound-desktop/src/main.ts`
- Create: `resound-desktop/src/App.vue`
- Create: `resound-desktop/src/vite-env.d.ts`
- Create: `resound-desktop/src-tauri/Cargo.toml`
- Create: `resound-desktop/src-tauri/tauri.conf.json`
- Create: `resound-desktop/src-tauri/src/main.rs`
- Create: `resound-desktop/src-tauri/src/lib.rs`

- [ ] **Step 1: Create project scaffold with Vite + Vue 3**

Run from `dynamic-island/`:

```bash
npm create vite@latest resound-desktop -- --template vue-ts
cd resound-desktop
npm install @tauri-apps/cli@next @tauri-apps/api@next
npm install
```

- [ ] **Step 2: Initialize Tauri**

```bash
cd resound-desktop
npx tauri init --app-name "Resound" --window-title "Resound" --dev-url http://localhost:5173 --before-dev-command "npm run dev" --before-build-command "npm run build" --frontend-dist ../dist
```

- [ ] **Step 3: Configure Tauri for always-on-top transparent window**

Edit `src-tauri/tauri.conf.json`:

```json
{
  "productName": "Resound",
  "version": "0.1.0",
  "identifier": "com.resound.app",
  "build": {
    "beforeDevCommand": "npm run dev",
    "beforeBuildCommand": "npm run build",
    "devUrl": "http://localhost:5173",
    "frontendDist": "../dist"
  },
  "app": {
    "windows": [
      {
        "title": "Resound",
        "width": 300,
        "height": 48,
        "decorations": false,
        "transparent": true,
        "alwaysOnTop": true,
        "skipTaskbar": true,
        "focusable": false,
        "resizable": false,
        "center": true,
        "visible": true
      }
    ],
    "withGlobalTauri": true,
    "security": {
      "csp": null
    }
  },
  "bundle": {
    "active": true,
    "targets": "all",
    "icon": [
      "icons/32x32.png",
      "icons/128x128.png",
      "icons/128x128@2x.png",
      "icons/icon.icns",
      "icons/icon.ico"
    ]
  }
}
```

- [ ] **Step 4: Configure Rust dependencies in `Cargo.toml`**

```toml
[package]
name = "resound"
version = "0.1.0"
edition = "2021"

[lib]
name = "resound_lib"
crate-type = ["staticlib", "cdylib", "rlib"]

[build-dependencies]
tauri-build = { version = "2", features = [] }

[dependencies]
tauri = { version = "2", features = ["tray-icon"] }
tauri-plugin-shell = "2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tokio = { version = "1", features = ["full"] }
futures = "0.3"
```

- [ ] **Step 5: Create minimal `lib.rs`**

```rust
use tauri::Manager;

#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}!", name)
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![greet])
        .setup(|app| {
            let _window = app.get_webview_window("main").unwrap();
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

- [ ] **Step 6: Create minimal `main.rs`**

```rust
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    resound_lib::run()
}
```

- [ ] **Step 7: Verify it builds**

```bash
cd resound-desktop
npx tauri build
```

Expected: Binary is created in `src-tauri/target/release/`.

- [ ] **Step 8: Commit**

```bash
cd dynamic-island
git add resound-desktop/
git commit -m "feat: scaffold Tauri + Vue 3 project for resound-desktop"
```

---

### Task 2: Media Integration — NowPlaying Abstraction (Rust)

**Files:**
- Create: `resound-desktop/src-tauri/src/media/mod.rs`
- Create: `resound-desktop/src-tauri/src/media/windows.rs`
- Create: `resound-desktop/src-tauri/src/media/linux.rs`

- [ ] **Step 1: Define the shared `NowPlayingInfo` type in `media/mod.rs`**

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct NowPlayingInfo {
    pub track_title: String,
    pub artist_name: String,
    pub album_title: String,
    pub is_playing: bool,
    pub progress: f64,
    pub duration: f64,
    pub volume: i32,
    pub artwork_base64: String,
    pub source: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct VolumeInfo {
    pub level: f64,
    pub muted: bool,
}

/// Platform-agnostic media provider trait.
pub trait MediaProvider: Send + Sync {
    fn current_track(&self) -> NowPlayingInfo;
    fn play_pause(&self);
    fn next_track(&self);
    fn prev_track(&self);
    fn volume(&self) -> VolumeInfo;
    fn set_volume(&self, level: f64);
}
```

- [ ] **Step 2: Create stub platform modules**

`media/windows.rs`:

```rust
use super::{MediaProvider, NowPlayingInfo, VolumeInfo};

pub struct WindowsMediaProvider;

impl WindowsMediaProvider {
    pub fn new() -> Self {
        Self
    }
}

impl MediaProvider for WindowsMediaProvider {
    fn current_track(&self) -> NowPlayingInfo {
        NowPlayingInfo::default()
    }

    fn play_pause(&self) {}
    fn next_track(&self) {}
    fn prev_track(&self) {}

    fn volume(&self) -> VolumeInfo {
        VolumeInfo { level: 0.5, muted: false }
    }

    fn set_volume(&self, _level: f64) {}
}
```

`media/linux.rs`:

```rust
use super::{MediaProvider, NowPlayingInfo, VolumeInfo};

pub struct LinuxMediaProvider;

impl LinuxMediaProvider {
    pub fn new() -> Self {
        Self
    }
}

impl MediaProvider for LinuxMediaProvider {
    fn current_track(&self) -> NowPlayingInfo {
        NowPlayingInfo::default()
    }

    fn play_pause(&self) {}
    fn next_track(&self) {}
    fn prev_track(&self) {}

    fn volume(&self) -> VolumeInfo {
        VolumeInfo { level: 0.5, muted: false }
    }

    fn set_volume(&self, _level: f64) {}
}
```

- [ ] **Step 3: Wire provider selection in `mod.rs`**

```rust
#[cfg(target_os = "windows")]
mod windows;
#[cfg(target_os = "linux")]
mod linux;

use std::sync::Mutex;

pub struct MediaManager {
    #[cfg(target_os = "windows")]
    provider: windows::WindowsMediaProvider,
    #[cfg(target_os = "linux")]
    provider: linux::LinuxMediaProvider,
}

impl MediaManager {
    pub fn new() -> Self {
        Self {
            #[cfg(target_os = "windows")]
            provider: windows::WindowsMediaProvider::new(),
            #[cfg(target_os = "linux")]
            provider: linux::LinuxMediaProvider::new(),
        }
    }

    pub fn get_current_track(&self) -> NowPlayingInfo {
        self.provider.current_track()
    }

    pub fn play_pause(&self) { self.provider.play_pause(); }
    pub fn next_track(&self) { self.provider.next_track(); }
    pub fn prev_track(&self) { self.provider.prev_track(); }

    pub fn volume(&self) -> VolumeInfo {
        self.provider.volume()
    }

    pub fn set_volume(&self, level: f64) {
        self.provider.set_volume(level);
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add resound-desktop/src-tauri/src/media/
git commit -m "feat: add media provider abstraction with platform stubs"
```

---

### Task 3: Windows Media Integration (Windows.Media.Control)

**Files:**
- Modify: `resound-desktop/src-tauri/src/media/windows.rs`
- Create: `resound-desktop/src-tauri/src/media/artwork_cache.rs`

- [ ] **Step 1: Add `windows` crate dependency to `Cargo.toml`**

```toml
[dependencies]
# ... existing
windows = { version = "0.58", features = [
    "Media_Control",
    "Media_MediaProperties",
    "Foundation",
    "Foundation_Collections",
    "Storage_Streams",
]}]
```

- [ ] **Step 2: Implement WindowsMediaProvider with GlobalSystemMediaTransportControlsSessionManager**

```rust
use windows::Media::Control::{
    GlobalSystemMediaTransportControlsSessionManager,
    GlobalSystemMediaTransportControlsSession,
    GlobalSystemMediaTransportControlsSessionPlaybackStatus,
};
use windows::Foundation::TimeSpan;
use std::sync::{Arc, Mutex};

pub struct WindowsMediaProvider {
    manager: Arc<Mutex<Option<GlobalSystemMediaTransportControlsSessionManager>>>,
}

impl WindowsMediaProvider {
    pub fn new() -> Self {
        Self {
            manager: Arc::new(Mutex::new(None)),
        }
    }

    async fn ensure_manager(&self) -> Option<GlobalSystemMediaTransportControlsSessionManager> {
        let mut guard = self.manager.lock().await;
        if guard.is_none() {
            *guard = GlobalSystemMediaTransportControlsSessionManager::RequestAsync()
                .await
                .ok();
        }
        guard.clone()
    }

    async fn current_session(&self) -> Option<GlobalSystemMediaTransportControlsSession> {
        let manager = self.ensure_manager().await?;
        manager.GetCurrentSession().ok()
    }
}
```

- [ ] **Step 3: Implement current_track for Windows**

```rust
use super::{NowPlayingInfo, VolumeInfo, MediaProvider};

impl MediaProvider for WindowsMediaProvider {
    fn current_track(&self) -> NowPlayingInfo {
        let session = match futures::executor::block_on(self.current_session()) {
            Some(s) => s,
            None => return NowPlayingInfo::default(),
        };

        let media_props = match futures::executor::block_on(session.TryGetMediaPropertiesAsync()) {
            Ok(props) => props,
            _ => return NowPlayingInfo::default(),
        };

        let title = media_props.Title().unwrap_or_default().to_string();
        let artist = media_props.Artist().unwrap_or_default().to_string();
        let album = media_props.AlbumTitle().unwrap_or_default().to_string();

        let playback = session.GetPlaybackInfo().ok();
        let is_playing = playback
            .and_then(|p| p.PlaybackStatus().ok())
            .map(|s| s == GlobalSystemMediaTransportControlsSessionPlaybackStatus::Playing)
            .unwrap_or(false);

        let timeline_props = session.GetTimelineProperties().ok();
        let (duration, position) = if let Some(tp) = timeline_props {
            let dur = tp.Duration().unwrap_or_default();
            let pos = tp.Position().unwrap_or_default();
            (TimeSpanToSecs(dur), TimeSpanToSecs(pos))
        } else {
            (0.0, 0.0)
        };

        // Artwork: get stream and convert to base64
        let artwork_b64 = Self::fetch_artwork_base64(&media_props);

        NowPlayingInfo {
            track_title: title,
            artist_name: artist,
            album_title: album,
            is_playing,
            progress: if duration > 0.0 { position / duration } else { 0.0 },
            duration,
            volume: 50,
            artwork_base64: artwork_b64,
            source: "Windows.Media.Control".into(),
        }
    }
}

fn TimeSpanToSecs(ts: TimeSpan) -> f64 {
    ts.Duration as f64 / 10_000_000.0
}
```

- [ ] **Step 4: Add artwork fetching helper to WindowsMediaProvider**

```rust
impl WindowsMediaProvider {
    fn fetch_artwork_base64(
        props: &windows::Media::MediaProperties::MediaItemDisplayProperties,
    ) -> String {
        use windows::Storage::Streams::InputStreamOptions;
        use windows::Media::MediaProperties::MediaThumbnail;

        let thumbnail = match props.Thumbnail().ok().and_then(|t| t.ok()) {
            Some(t) => t,
            None => return String::new(),
        };

        let stream = match thumbnail.OpenReadAsync().ok() {
            Some(s) => s,
            None => return String::new(),
        };

        let reader = match windows::Storage::Streams::DataReader::CreateDataReader(&stream) {
            Ok(r) => r,
            _ => return String::new(),
        };

        let size = stream.Size() as u32;
        if size == 0 || size > 5_000_000 {
            return String::new();
        }

        let _ = reader.LoadAsync(size).ok();
        let mut buffer = vec![0u8; size as usize];
        if reader.ReadBytes(&mut buffer).is_err() {
            return String::new();
        }

        use base64::Engine;
        base64::engine::general_purpose::STANDARD.encode(&buffer)
    }
}
```

Also add `base64` to `Cargo.toml`:

```toml
base64 = "0.22"
```

- [ ] **Step 5: Add transport controls for Windows**

```rust
fn play_pause(&self) {
    if let Some(session) = futures::executor::block_on(self.current_session()) {
        let status = session.GetPlaybackInfo()
            .ok()
            .and_then(|p| p.PlaybackStatus().ok());
        match status {
            Some(GlobalSystemMediaTransportControlsSessionPlaybackStatus::Playing) => {
                let _ = futures::executor::block_on(session.TryPauseAsync());
            }
            _ => {
                let _ = futures::executor::block_on(session.TryPlayAsync());
            }
        }
    }
}

fn next_track(&self) {
    if let Some(session) = futures::executor::block_on(self.current_session()) {
        let _ = futures::executor::block_on(session.TrySkipNextAsync());
    }
}

fn prev_track(&self) {
    if let Some(session) = futures::executor::block_on(self.current_session()) {
        let _ = futures::executor::block_on(session.TrySkipPreviousAsync());
    }
}
```

- [ ] **Step 6: Commit**

```bash
git add resound-desktop/src-tauri/src/media/windows.rs resound-desktop/src-tauri/src/media/artwork_cache.rs
git commit -m "feat: implement Windows media integration via Windows.Media.Control"
```

---

### Task 4: Linux Media Integration (MPRIS D-Bus)

**Files:**
- Modify: `resound-desktop/src-tauri/src/media/linux.rs`

- [ ] **Step 1: Add `zbus` dependency to `Cargo.toml`**

```toml
[target.'cfg(target_os = "linux")'.dependencies]
zbus = { version = "4", features = ["blocking-api"] }
```

- [ ] **Step 2: Implement LinuxMediaProvider with MPRIS D-Bus**

```rust
use super::{MediaProvider, NowPlayingInfo, VolumeInfo};
use zbus::blocking::Connection;
use zbus::dbus_proxy;
use std::time::Duration;

#[dbus_proxy(
    interface = "org.mpris.MediaPlayer2.Player",
    default_service = "org.mpris.MediaPlayer2.spotify",
    default_path = "/org/mpris/MediaPlayer2"
)]
trait MprisPlayer {
    fn Play(&self) -> zbus::Result<()>;
    fn Pause(&self) -> zbus::Result<()>;
    fn PlayPause(&self) -> zbus::Result<()>;
    fn Next(&self) -> zbus::Result<()>;
    fn Previous(&self) -> zbus::Result<()>;
    fn Metadata(&self) -> zbus::Result<std::collections::HashMap<String, zbus::zvariant::Value>>;
    fn PlaybackStatus(&self) -> zbus::Result<String>;
    fn Position(&self) -> zbus::Result<i64>;
}

#[dbus_proxy(
    interface = "org.mpris.MediaPlayer2",
    default_service = "org.mpris.MediaPlayer2.spotify",
    default_path = "/org/mpris/MediaPlayer2"
)]
trait MprisRoot {
    fn Identity(&self) -> zbus::Result<String>;
}

pub struct LinuxMediaProvider {
    connection: Option<Connection>,
}

fn find_mpris_players(conn: &Connection) -> Vec<String> {
    let bus = match conn.call_method(
        Some("org.freedesktop.DBus"),
        "/org/freedesktop/DBus",
        Some("org.freedesktop.DBus"),
        "ListNames",
        &(),
    ) {
        Ok(m) => m,
        _ => return vec![],
    };
    let names: Vec<String> = bus.body().unwrap_or_default();
    names.into_iter().filter(|n| n.contains("org.mpris.MediaPlayer2")).collect()
}

impl LinuxMediaProvider {
    pub fn new() -> Self {
        let conn = Connection::session().ok();
        Self { connection: conn }
    }

    fn best_player(&self) -> Option<(String, MprisPlayerProxy<'_>)> {
        let conn = self.connection.as_ref()?;
        let players = find_mpris_players(conn);
        for name in &players {
            let proxy = MprisPlayerProxy::new_for_name(conn, name, Duration::from_secs(1)).ok()?;
            return Some((name.clone(), proxy));
        }
        None
    }
}

impl MediaProvider for LinuxMediaProvider {
    fn current_track(&self) -> NowPlayingInfo {
        let (_, player) = match self.best_player() {
            Some(p) => p,
            None => return NowPlayingInfo::default(),
        };

        let metadata = player.Metadata().unwrap_or_default();
        let status = player.PlaybackStatus().unwrap_or_default();
        let position_us = player.Position().unwrap_or(0);

        let title = metadata.get("xesam:title")
            .and_then(|v| v.downcast_ref::<String>())
            .cloned()
            .unwrap_or_default();
        let artist = metadata.get("xesam:artist")
            .and_then(|v| v.downcast_ref::<Vec<String>>())
            .and_then(|a| a.first().cloned())
            .unwrap_or_default();
        let album = metadata.get("xesam:album")
            .and_then(|v| v.downcast_ref::<String>())
            .cloned()
            .unwrap_or_default();
        let duration_us = metadata.get("mpris:length")
            .and_then(|v| v.downcast_ref::<i64>())
            .copied()
            .unwrap_or(0);

        let duration_secs = duration_us as f64 / 1_000_000.0;
        let position_secs = position_us as f64 / 1_000_000.0;

        // Artwork URL from MPRIS
        let artwork_url = metadata.get("mpris:artUrl")
            .and_then(|v| v.downcast_ref::<String>())
            .cloned()
            .unwrap_or_default();

        // Download artwork and convert to base64
        let artwork_b64 = Self::fetch_artwork_base64(&artwork_url);

        NowPlayingInfo {
            track_title: title,
            artist_name: artist,
            album_title: album,
            is_playing: status == "Playing",
            progress: if duration_secs > 0.0 { position_secs / duration_secs } else { 0.0 },
            duration: duration_secs,
            volume: 50,
            artwork_base64: artwork_b64,
            source: "MPRIS".into(),
        }
    }

    fn play_pause(&self) {
        if let Some((_name, player)) = self.best_player() {
            let _ = player.PlayPause();
        }
    }

    fn next_track(&self) {
        if let Some((_name, player)) = self.best_player() {
            let _ = player.Next();
        }
    }

    fn prev_track(&self) {
        if let Some((_name, player)) = self.best_player() {
            let _ = player.Previous();
        }
    }

    fn volume(&self) -> VolumeInfo {
        VolumeInfo { level: 0.5, muted: false }
    }

    fn set_volume(&self, _level: f64) {}
}

impl LinuxMediaProvider {
    fn fetch_artwork_base64(url: &str) -> String {
        if url.is_empty() { return String::new(); }
        match reqwest::blocking::get(url) {
            Ok(resp) => {
                let bytes = match resp.bytes() {
                    Ok(b) => b.to_vec(),
                    _ => return String::new(),
                };
                use base64::Engine;
                base64::engine::general_purpose::STANDARD.encode(&bytes)
            }
            _ => String::new(),
        }
    }
}
```

Add `reqwest` to `Cargo.toml`:

```toml
reqwest = { version = "0.12", features = ["blocking"] }
```

- [ ] **Step 3: Commit**

```bash
git add resound-desktop/src-tauri/src/media/linux.rs
git commit -m "feat: implement Linux media integration via MPRIS D-Bus"
```

---

### Task 5: System Tray + App State (Rust)

**Files:**
- Create: `resound-desktop/src-tauri/tray.rs`
- Modify: `resound-desktop/src-tauri/src/lib.rs`
- Modify: `resound-desktop/src-tauri/src/main.rs`

- [ ] **Step 1: Create tray module in `tray.rs`**

```rust
use tauri::{
    AppHandle, Wry, Manager,
    tray::{TrayIconBuilder, TrayIconEvent, MouseButton, MouseButtonState},
};
use tauri::menu::{MenuBuilder, MenuItemBuilder};

pub fn setup_tray(app: &AppHandle<Wry>) -> Result<(), Box<dyn std::error::Error>> {
    let show = MenuItemBuilder::with_id("show", "Show/Hide Resound").build(app)?;
    let quit = MenuItemBuilder::with_id("quit", "Quit Resound").build(app)?;
    let menu = MenuBuilder::new(app)
        .item(&show)
        .separator()
        .item(&quit)
        .build()?;

    TrayIconBuilder::new()
        .icon(app.default_window_icon().unwrap().clone())
        .menu(&menu)
        .on_menu_event(|app, event| match event.id().as_ref() {
            "quit" => app.exit(0),
            "show" => {
                if let Some(w) = app.get_webview_window("main") {
                    if w.is_visible().unwrap_or(false) {
                        let _ = w.hide();
                    } else {
                        let _ = w.show();
                        let _ = w.set_focus();
                    }
                }
            }
            _ => {}
        })
        .on_tray_icon_event(|tray, event| {
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            } = event {
                let app = tray.app_handle();
                if let Some(w) = app.get_webview_window("main") {
                    if w.is_visible().unwrap_or(false) {
                        let _ = w.hide();
                    } else {
                        let _ = w.show();
                        let _ = w.set_focus();
                    }
                }
            }
        })
        .build(app)?;

    Ok(())
}
```

- [ ] **Step 2: Wire tray + media manager in `lib.rs`**

```rust
use tauri::Manager;
use std::sync::Mutex;

mod media;
mod tray;

pub struct AppState {
    pub media_manager: media::MediaManager,
}

#[tauri::command]
fn get_now_playing(state: tauri::State<'_, Mutex<AppState>>) -> media::NowPlayingInfo {
    let app_state = state.lock().unwrap();
    app_state.media_manager.get_current_track()
}

#[tauri::command]
fn play_pause(state: tauri::State<'_, Mutex<AppState>>) {
    let app_state = state.lock().unwrap();
    app_state.media_manager.play_pause();
}

#[tauri::command]
fn next_track(state: tauri::State<'_, Mutex<AppState>>) {
    let app_state = state.lock().unwrap();
    app_state.media_manager.next_track();
}

#[tauri::command]
fn prev_track(state: tauri::State<'_, Mutex<AppState>>) {
    let app_state = state.lock().unwrap();
    app_state.media_manager.prev_track();
}

#[tauri::command]
fn get_volume(state: tauri::State<'_, Mutex<AppState>>) -> media::VolumeInfo {
    let app_state = state.lock().unwrap();
    app_state.media_manager.volume()
}

#[tauri::command]
fn set_volume(level: f64, state: tauri::State<'_, Mutex<AppState>>) {
    let app_state = state.lock().unwrap();
    app_state.media_manager.set_volume(level);
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .manage(Mutex::new(AppState {
            media_manager: media::MediaManager::new(),
        }))
        .invoke_handler(tauri::generate_handler![
            get_now_playing,
            play_pause,
            next_track,
            prev_track,
            get_volume,
            set_volume,
        ])
        .setup(|app| {
            let _ = tray::setup_tray(app.handle());
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

- [ ] **Step 3: Update `main.rs` if needed (import change)**

No changes needed — `main.rs` already calls `resound_lib::run()`.

- [ ] **Step 4: Build check**

```bash
cd resound-desktop
cargo build --manifest-path src-tauri/Cargo.toml
```

Expected: Compiles without errors (stub providers return defaults for now).

- [ ] **Step 5: Commit**

```bash
git add resound-desktop/src-tauri/tray.rs resound-desktop/src-tauri/src/lib.rs
git commit -m "feat: add system tray and wire IPC commands"
```

---

### Task 6: Vue 3 Frontend — Composable State

**Files:**
- Create: `resound-desktop/src/composables/useNowPlaying.ts`
- Create: `resound-desktop/src/composables/useVolume.ts`

- [ ] **Step 1: Create `useNowPlaying.ts`**

```typescript
import { reactive, onMounted, onUnmounted } from 'vue'
import { invoke } from '@tauri-apps/api/core'
import { listen } from '@tauri-apps/api/event'

export interface NowPlayingInfo {
  track_title: string
  artist_name: string
  album_title: string
  is_playing: boolean
  progress: number
  duration: number
  volume: number
  artwork_base64: string
  source: string
}

const emptyTrack: NowPlayingInfo = {
  track_title: '',
  artist_name: '',
  album_title: '',
  is_playing: false,
  progress: 0,
  duration: 0,
  volume: 50,
  artwork_base64: '',
  source: '',
}

const state = reactive<{
  current: NowPlayingInfo
  loading: boolean
  error: string | null
}>({
  current: { ...emptyTrack },
  loading: false,
  error: null,
})

let unlisten: (() => void) | null = null
let pollInterval: ReturnType<typeof setInterval> | null = null

export function useNowPlaying() {
  async function fetch() {
    state.loading = true
    try {
      state.current = await invoke<NowPlayingInfo>('get_now_playing')
      state.error = null
    } catch (e) {
      state.error = String(e)
    } finally {
      state.loading = false
    }
  }

  async function playPause() {
    await invoke('play_pause')
    await fetch()
  }

  async function nextTrack() {
    await invoke('next_track')
    await fetch()
  }

  async function prevTrack() {
    await invoke('prev_track')
    await fetch()
  }

  onMounted(async () => {
    await fetch()
    // Poll every 1s as fallback
    pollInterval = setInterval(fetch, 1000)
    // Listen for push events from backend
    unlisten = await listen<NowPlayingInfo>('now-playing-changed', (event) => {
      state.current = event.payload
    })
  })

  onUnmounted(() => {
    if (pollInterval) clearInterval(pollInterval)
    if (unlisten) unlisten()
  })

  return {
    state,
    fetch,
    playPause,
    nextTrack,
    prevTrack,
  }
}
```

- [ ] **Step 2: Create `useVolume.ts`**

```typescript
import { reactive } from 'vue'
import { invoke } from '@tauri-apps/api/core'
import { listen } from '@tauri-apps/api/event'

export interface VolumeInfo {
  level: number
  muted: boolean
}

const state = reactive<{
  level: number
  muted: boolean
}>({
  level: 50,
  muted: false,
})

let unlisten: (() => void) | null = null

export function useVolume() {
  async function fetchVolume() {
    try {
      const info = await invoke<VolumeInfo>('get_volume')
      state.level = Math.round(info.level * 100)
      state.muted = info.muted
    } catch {}
  }

  async function setVolume(level: number) {
    state.level = level
    try {
      await invoke('set_volume', { level: level / 100 })
    } catch {}
  }

  async function init() {
    await fetchVolume()
    unlisten = await listen<VolumeInfo>('volume-changed', (event) => {
      state.level = Math.round(event.payload.level * 100)
      state.muted = event.payload.muted
    })
  }

  return {
    state,
    fetchVolume,
    setVolume,
    init,
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add resound-desktop/src/composables/
git commit -m "feat: add Vue composables for now-playing and volume state"
```

---

### Task 7: Vue 3 Frontend — Pill UI Component

**Files:**
- Create: `resound-desktop/src/components/Pill.vue`

- [ ] **Step 1: Create `Pill.vue`**

```vue
<script setup lang="ts">
import { ref } from 'vue'
import { useNowPlaying } from '../composables/useNowPlaying'

const { state } = useNowPlaying()
const isHovering = ref(false)

const emit = defineEmits<{
  (e: 'expand', v: boolean): void
}>()

function onHover(v: boolean) {
  isHovering.value = v
  emit('expand', v)
}

function artworkUrl(): string {
  if (!state.current.artwork_base64) return ''
  return `data:image/jpeg;base64,${state.current.artwork_base64}`
}
</script>

<template>
  <div
    class="pill"
    @mouseenter="onHover(true)"
    @mouseleave="onHover(false)"
    :class="{ hovering: isHovering }"
  >
    <div class="pill-content">
      <div class="artwork" v-if="state.current.track_title">
        <img v-if="artworkUrl()" :src="artworkUrl()" alt="" />
        <div v-else class="artwork-fallback">
          <span>♪</span>
        </div>
      </div>
      <div class="empty-icon" v-else>
        <span>♪</span>
      </div>
      <div class="waveform">
        <span v-for="i in 4" :key="i" class="bar" :style="{ animationDelay: `${i * 0.15}s` }"></span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.pill {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  transition: transform 0.15s ease;
}

.pill.hovering {
  transform: scale(1.03);
}

.pill-content {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 10px;
}

.artwork img {
  width: 22px;
  height: 22px;
  border-radius: 6px;
  object-fit: cover;
}

.artwork-fallback,
.empty-icon {
  width: 22px;
  height: 22px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  color: rgba(255, 255, 255, 0.5);
}

.artwork-fallback {
  background: linear-gradient(135deg, #e91e63, #f44336);
}

.empty-icon span {
  color: #888;
  font-size: 11px;
}

.waveform {
  display: flex;
  align-items: center;
  gap: 2px;
  height: 28px;
}

.bar {
  width: 3px;
  height: 100%;
  background: rgba(255, 255, 255, 0.4);
  border-radius: 2px;
  animation: wave 1s ease-in-out infinite;
}

@keyframes wave {
  0%, 100% { height: 20%; }
  50% { height: 80%; }
}
</style>
```

- [ ] **Step 2: Commit**

```bash
git add resound-desktop/src/components/Pill.vue
git commit -m "feat: add Pill UI component"
```

---

### Task 8: Vue 3 Frontend — Expanded Panel + Transport Controls

**Files:**
- Create: `resound-desktop/src/components/ExpandedPanel.vue`
- Create: `resound-desktop/src/components/TransportControls.vue`
- Create: `resound-desktop/src/components/VolumeSlider.vue`

- [ ] **Step 1: Create `VolumeSlider.vue`**

```vue
<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  volume: number
}>()

const emit = defineEmits<{
  (e: 'setVolume', v: number): void
}>()

const iconName = computed(() => {
  if (props.volume === 0) return '🔇'
  if (props.volume < 30) return '🔈'
  if (props.volume < 70) return '🔉'
  return '🔊'
})

function onInput(e: Event) {
  const target = e.target as HTMLInputElement
  emit('setVolume', parseInt(target.value))
}
</script>

<template>
  <div class="volume-slider">
    <span class="icon">{{ iconName }}</span>
    <input
      type="range"
      min="0"
      max="100"
      :value="volume"
      @input="onInput"
      class="slider"
    />
    <span class="label">{{ volume }}%</span>
  </div>
</template>

<style scoped>
.volume-slider {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px 16px;
}

.icon {
  font-size: 11px;
  width: 16px;
  text-align: center;
  opacity: 0.6;
}

.slider {
  flex: 1;
  -webkit-appearance: none;
  appearance: none;
  height: 3px;
  border-radius: 2px;
  background: rgba(255, 255, 255, 0.15);
  outline: none;
}

.slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: white;
  cursor: pointer;
}

.label {
  font-size: 10px;
  font-weight: 600;
  opacity: 0.4;
  min-width: 28px;
  text-align: right;
  font-variant-numeric: tabular-nums;
}
</style>
```

- [ ] **Step 2: Create `TransportControls.vue`**

```vue
<script setup lang="ts">
import { useNowPlaying } from '../composables/useNowPlaying'

const { state, playPause, nextTrack, prevTrack } = useNowPlaying()
</script>

<template>
  <div class="transport">
    <button class="ctrl-btn" @click="prevTrack">⏮</button>
    <button class="play-btn" @click="playPause">
      {{ state.current.is_playing ? '⏸' : '▶' }}
    </button>
    <button class="ctrl-btn" @click="nextTrack">⏭</button>
  </div>
</template>

<style scoped>
.transport {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 28px;
  padding: 8px 16px;
}

.ctrl-btn {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.45);
  font-size: 16px;
  cursor: pointer;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.12s ease, opacity 0.12s ease;
}

.ctrl-btn:active {
  transform: scale(0.92);
  opacity: 0.7;
}

.play-btn {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: white;
  border: none;
  color: black;
  font-size: 14px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.12s ease;
}

.play-btn:active {
  transform: scale(0.92);
}
</style>
```

- [ ] **Step 3: Create `ExpandedPanel.vue`**

```vue
<script setup lang="ts">
import { computed } from 'vue'
import { useNowPlaying } from '../composables/useNowPlaying'
import { useVolume } from '../composables/useVolume'
import TransportControls from './TransportControls.vue'
import VolumeSlider from './VolumeSlider.vue'

const { state } = useNowPlaying()
const volume = useVolume()

const elapsedText = computed(() => {
  const t = state.current.progress * state.current.duration
  const m = Math.floor(t / 60)
  const s = Math.floor(t % 60)
  return `${m}:${s.toString().padStart(2, '0')}`
})

const remainingText = computed(() => {
  const t = (1 - state.current.progress) * state.current.duration
  const m = Math.floor(t / 60)
  const s = Math.floor(t % 60)
  return `${m}:${s.toString().padStart(2, '0')}`
})

const progressStyle = computed(() => ({
  width: `${state.current.progress * 100}%`
}))

function artworkUrl(): string {
  if (!state.current.artwork_base64) return ''
  return `data:image/jpeg;base64,${state.current.artwork_base64}`
}
</script>

<template>
  <div class="expanded" v-if="state.current.track_title">
    <div class="top-row">
      <div class="artwork-lg">
        <img v-if="artworkUrl()" :src="artworkUrl()" alt="" />
        <div v-else class="artwork-fallback">♪</div>
      </div>
      <div class="track-info">
        <div class="title">{{ state.current.track_title }}</div>
        <div class="artist">{{ state.current.artist_name }}</div>
      </div>
    </div>

    <div class="progress-row">
      <div class="progress-track">
        <div class="progress-fill" :style="progressStyle"></div>
      </div>
    </div>

    <div class="time-row">
      <span class="time">{{ elapsedText }}</span>
      <span class="time">-{{ remainingText }}</span>
    </div>

    <TransportControls />
    <VolumeSlider :volume="volume.state.level" @set-volume="volume.setVolume" />
  </div>

  <div class="expanded empty" v-else>
    <div class="empty-state">
      <span class="empty-icon">♪</span>
      <span class="empty-text">Nothing is playing</span>
    </div>
  </div>
</template>

<style scoped>
.expanded {
  width: 100%;
}

.top-row {
  display: flex;
  gap: 14px;
  padding: 16px 16px 0;
}

.artwork-lg img {
  width: 52px;
  height: 52px;
  border-radius: 10px;
  object-fit: cover;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

.artwork-fallback {
  width: 52px;
  height: 52px;
  border-radius: 10px;
  background: linear-gradient(135deg, #9c27b0, #009688);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  color: rgba(255, 255, 255, 0.8);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

.track-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 2px;
  min-width: 0;
}

.title {
  font-size: 14px;
  font-weight: 600;
  color: white;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.artist {
  font-size: 11px;
  opacity: 0.45;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.progress-row {
  padding: 10px 16px 0;
}

.progress-track {
  height: 3px;
  background: rgba(255, 255, 255, 0.08);
  border-radius: 2px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 2px;
  transition: width 0.25s linear;
}

.time-row {
  display: flex;
  justify-content: space-between;
  padding: 4px 16px 0;
}

.time {
  font-size: 10px;
  font-weight: 500;
  opacity: 0.4;
  font-variant-numeric: tabular-nums;
}

.empty {
  height: 100px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  opacity: 0.3;
}

.empty-icon {
  font-size: 20px;
}

.empty-text {
  font-size: 12px;
}
</style>
```

- [ ] **Step 4: Commit**

```bash
git add resound-desktop/src/components/ExpandedPanel.vue resound-desktop/src/components/TransportControls.vue resound-desktop/src/components/VolumeSlider.vue
git commit -m "feat: add expanded panel, transport controls, and volume slider"
```

---

### Task 9: Vue 3 Frontend — Volume Overlay OSD

**Files:**
- Create: `resound-desktop/src/components/VolumeOverlay.vue`
- Create: `resound-desktop/src/composables/useVolumeOverlay.ts`

- [ ] **Step 1: Create `useVolumeOverlay.ts`**

```typescript
import { reactive } from 'vue'
import { listen } from '@tauri-apps/api/event'

export interface OverlayState {
  visible: boolean
  level: number
  muted: boolean
  mode: 'volume' | 'brightness'
}

const state = reactive<OverlayState>({
  visible: false,
  level: 0.5,
  muted: false,
  mode: 'volume',
})

let hideTimer: ReturnType<typeof setTimeout> | null = null
let unlisten: (() => void) | null = null

export function useVolumeOverlay() {
  function show(level: number, muted: boolean, mode: 'volume' | 'brightness' = 'volume') {
    state.level = level
    state.muted = muted
    state.mode = mode
    state.visible = true

    if (hideTimer) clearTimeout(hideTimer)
    hideTimer = setTimeout(() => {
      state.visible = false
    }, 1000)
  }

  function hide() {
    state.visible = false
    if (hideTimer) clearTimeout(hideTimer)
  }

  async function init() {
    unlisten = await listen<{ level: number; muted: boolean }>('volume-changed', (event) => {
      show(event.payload.level, event.payload.muted)
    })
  }

  return { state, show, hide, init }
}
```

- [ ] **Step 2: Create `VolumeOverlay.vue`**

```vue
<script setup lang="ts">
import { computed } from 'vue'
import { useVolumeOverlay } from '../composables/useVolumeOverlay'

const overlay = useVolumeOverlay()

const iconName = computed(() => {
  if (overlay.state.mode === 'brightness') return '☀'
  if (overlay.state.muted || overlay.state.level === 0) return '🔇'
  if (overlay.state.level < 0.2) return '🔈'
  if (overlay.state.level < 0.5) return '🔉'
  return '🔊'
})

const bars = computed(() => {
  const count = 8
  const fill = Math.round(overlay.state.level * count)
  return Array.from({ length: count }, (_, i) => i < fill)
})

const pct = computed(() => `${Math.round(overlay.state.level * 100)}%`)
</script>

<template>
  <Transition name="fade">
    <div class="overlay" v-if="overlay.state.visible">
      <div class="overlay-inner">
        <span class="icon">{{ iconName }}</span>
        <div class="bars">
          <div
            v-for="(active, i) in bars"
            :key="i"
            class="bar"
            :class="{ active }"
            :style="{ opacity: active ? (i === bars.length - 1 ? 0.5 : 0.7) : 0.1 }"
          ></div>
        </div>
        <span class="pct">{{ pct }}</span>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.overlay {
  position: fixed;
  top: 16px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 9999;
  pointer-events: none;
}

.overlay-inner {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 16px;
  background: #0f0f0f;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 14px;
}

.icon {
  font-size: 13px;
  width: 18px;
  text-align: center;
  opacity: 0.6;
}

.bars {
  display: flex;
  align-items: center;
  gap: 3px;
  height: 22px;
}

.bar {
  width: 6px;
  height: 100%;
  border-radius: 3px;
  background: white;
  transition: opacity 0.1s;
}

.bar.active {
  background: white;
}

.pct {
  font-size: 10px;
  font-weight: 600;
  opacity: 0.4;
  font-variant-numeric: tabular-nums;
  min-width: 30px;
  text-align: right;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
```

- [ ] **Step 3: Commit**

```bash
git add resound-desktop/src/components/VolumeOverlay.vue resound-desktop/src/composables/useVolumeOverlay.ts
git commit -m "feat: add volume OSD overlay component"
```

---

### Task 10: Vue 3 Frontend — Settings Panel

**Files:**
- Create: `resound-desktop/src/components/SettingsPanel.vue`
- Create: `resound-desktop/src/composables/useSettings.ts`

- [ ] **Step 1: Create `useSettings.ts`**

```typescript
import { reactive } from 'vue'
import { invoke } from '@tauri-apps/api/core'

interface Settings {
  autoHide: boolean
  launchAtLogin: boolean
  musicSource: 'automatic' | 'spotify'
}

const state = reactive<Settings>({
  autoHide: true,
  launchAtLogin: false,
  musicSource: 'automatic',
})

export function useSettings() {
  async function load() {
    try {
      const s = await invoke<Settings>('get_settings')
      Object.assign(state, s)
    } catch {}
  }

  async function save() {
    try {
      await invoke('set_settings', { settings: { ...state } })
    } catch {}
  }

  function setAutoHide(v: boolean) {
    state.autoHide = v
    save()
  }

  function setLaunchAtLogin(v: boolean) {
    state.launchAtLogin = v
    save()
  }

  function setMusicSource(v: Settings['musicSource']) {
    state.musicSource = v
    save()
  }

  return { state, load, save, setAutoHide, setLaunchAtLogin, setMusicSource }
}
```

- [ ] **Step 2: Create `SettingsPanel.vue`**

```vue
<script setup lang="ts">
import { ref } from 'vue'
import { useSettings } from '../composables/useSettings'

const settings = useSettings()
const open = ref(false)
</script>

<template>
  <div class="settings-wrapper">
    <button class="gear" @click="open = !open">⚙</button>
    <Transition name="slide">
      <div class="panel" v-if="open">
        <label class="row">
          <span>Auto-hide</span>
          <input type="checkbox" :checked="settings.state.autoHide" @change="settings.setAutoHide(($event.target as HTMLInputElement).checked)" />
        </label>
        <label class="row">
          <span>Launch at login</span>
          <input type="checkbox" :checked="settings.state.launchAtLogin" @change="settings.setLaunchAtLogin(($event.target as HTMLInputElement).checked)" />
        </label>
        <label class="row">
          <span>Source</span>
          <select :value="settings.state.musicSource" @change="settings.setMusicSource(($event.target as HTMLSelectElement).value as any)">
            <option value="automatic">Automatic</option>
            <option value="spotify">Spotify only</option>
          </select>
        </label>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.settings-wrapper {
  position: relative;
}

.gear {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.3);
  font-size: 14px;
  cursor: pointer;
  padding: 4px 8px;
}

.gear:hover {
  opacity: 0.7;
}

.panel {
  position: absolute;
  bottom: 100%;
  right: 0;
  background: #111;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 10px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  min-width: 180px;
  margin-bottom: 4px;
}

.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 12px;
  gap: 12px;
  cursor: pointer;
}

.row input[type="checkbox"] {
  accent-color: white;
}

.row select {
  background: #222;
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: white;
  font-size: 11px;
  padding: 2px 6px;
  border-radius: 4px;
}

.slide-enter-active,
.slide-leave-active {
  transition: opacity 0.12s ease, transform 0.12s ease;
}

.slide-enter-from,
.slide-leave-to {
  opacity: 0;
  transform: translateY(4px);
}
</style>
```

- [ ] **Step 3: Add get_settings / set_settings IPC commands to Rust `lib.rs`**

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppSettings {
    pub auto_hide: bool,
    pub launch_at_login: bool,
    pub music_source: String,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            auto_hide: true,
            launch_at_login: false,
            music_source: "automatic".into(),
        }
    }
}

#[tauri::command]
fn get_settings(state: tauri::State<'_, Mutex<AppState>>) -> AppSettings {
    let app_state = state.lock().unwrap();
    app_state.settings.lock().unwrap().clone()
}

#[tauri::command]
fn set_settings(settings: AppSettings, state: tauri::State<'_, Mutex<AppState>>) {
    let app_state = state.lock().unwrap();
    *app_state.settings.lock().unwrap() = settings;
}
```

Also update `AppState`:
```rust
pub struct AppState {
    pub media_manager: media::MediaManager,
    pub settings: Mutex<AppSettings>,
}
```

And register the new commands:
```rust
.invoke_handler(tauri::generate_handler![
    get_now_playing,
    play_pause,
    next_track,
    prev_track,
    get_volume,
    set_volume,
    get_settings,
    set_settings,
])
```

- [ ] **Step 4: Commit**

```bash
git add resound-desktop/src/components/SettingsPanel.vue resound-desktop/src/composables/useSettings.ts
git commit -m "feat: add settings panel and IPC"
```

---

### Task 11: Vue 3 Frontend — Root App + Integration

**Files:**
- Modify: `resound-desktop/src/App.vue`
- Modify: `resound-desktop/src/main.ts`
- Modify: `resound-desktop/src/styles.css`

- [ ] **Step 1: Create global styles in `src/assets/styles.css`**

```css
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body, #app {
  width: 100%;
  height: 100%;
  overflow: hidden;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  background: transparent;
  color: white;
  user-select: none;
  -webkit-user-select: none;
}
```

- [ ] **Step 2: Update `main.ts` to import styles + init composables**

```typescript
import { createApp } from 'vue'
import App from './App.vue'
import { useVolume } from './composables/useVolume'
import { useVolumeOverlay } from './composables/useVolumeOverlay'
import { useSettings } from './composables/useSettings'
import './assets/styles.css'

const app = createApp(App)
app.mount('#app')

// Initialize background listeners
useVolume().init()
useVolumeOverlay().init()
useSettings().load()
```

- [ ] **Step 3: Rewrite `App.vue`**

```vue
<script setup lang="ts">
import { ref } from 'vue'
import Pill from './components/Pill.vue'
import ExpandedPanel from './components/ExpandedPanel.vue'
import VolumeOverlay from './components/VolumeOverlay.vue'
import SettingsPanel from './components/SettingsPanel.vue'

const expanded = ref(false)
</script>

<template>
  <div class="window" @mouseenter="expanded = true" @mouseleave="expanded = false">
    <div class="container" :class="{ expanded }">
      <Pill @expand="expanded = $event" />
      <Transition name="panel">
        <div class="panel-wrap" v-if="expanded">
          <div class="divider"></div>
          <ExpandedPanel />
        </div>
      </Transition>
    </div>
    <div class="settings-pos">
      <SettingsPanel />
    </div>
  </div>
  <VolumeOverlay />
</template>

<style scoped>
.window {
  width: 100vw;
  height: 100vh;
  background: transparent;
  position: relative;
}

.container {
  background: rgba(12, 12, 12, 0.95);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 16px;
  overflow: hidden;
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  min-width: 200px;
  max-width: 320px;
  transition: all 0.2s ease;
}

.container.expanded {
  min-width: 280px;
}

.panel-wrap {
  overflow: hidden;
}

.divider {
  height: 1px;
  background: rgba(255, 255, 255, 0.06);
  margin: 0;
}

.settings-pos {
  position: absolute;
  top: 4px;
  right: 4px;
  z-index: 10;
}

.panel-enter-active,
.panel-leave-active {
  transition: max-height 0.2s ease, opacity 0.15s ease;
  max-height: 300px;
}

.panel-enter-from,
.panel-leave-to {
  max-height: 0;
  opacity: 0;
}
</style>
```

- [ ] **Step 4: Commit**

```bash
git add resound-desktop/src/App.vue resound-desktop/src/main.ts resound-desktop/src/assets/styles.css
git commit -m "feat: integrate all components in root App"
```

---

### Task 12: Window Positioning + Cross-Platform Polish

**Files:**
- Create: `resound-desktop/src-tauri/src/positioning.rs`
- Modify: `resound-desktop/src-tauri/src/lib.rs`
- Modify: `resound-desktop/src-tauri/tauri.conf.json`

- [ ] **Step 1: Create `positioning.rs`**

```rust
use tauri::{Manager, Wry};
use tauri::WebviewWindow;

pub fn center_window_at_top(window: &WebviewWindow<Wry>) {
    if let Some(monitor) = window.current_monitor().ok().flatten() {
        let screen_size = monitor.size();
        let scale = monitor.scale_factor();
        let win_size = window.outer_size().ok().unwrap_or_default();

        let x = ((screen_size.width as f64) - (win_size.width as f64)) / 2.0;
        let y = 24.0; // small top margin

        let _ = window.set_position(tauri::Position::Physical(
            tauri::PhysicalPosition::new(x as i32, y as i32),
        ));
    }
}

pub fn position_overlay(window: &WebviewWindow<Wry>, width: u32, height: u32) {
    if let Some(monitor) = window.current_monitor().ok().flatten() {
        let screen_size = monitor.size();
        let x = ((screen_size.width as f64) - width as f64) / 2.0;
        let y = 24.0;
        let _ = window.set_position(tauri::Position::Physical(
            tauri::PhysicalPosition::new(x as i32, y as i32),
        ));
    }
}
```

- [ ] **Step 2: Wire positioning in `lib.rs` setup**

```rust
.setup(|app| {
    let _ = tray::setup_tray(app.handle());
    if let Some(window) = app.get_webview_window("main") {
        positioning::center_window_at_top(&window);
    }
    Ok(())
})
```

- [ ] **Step 3: Update `tauri.conf.json` window config**

```json
"windows": [
  {
    "title": "Resound",
    "width": 280,
    "height": 48,
    "decorations": false,
    "transparent": true,
    "alwaysOnTop": true,
    "skipTaskbar": true,
    "focusable": false,
    "resizable": false,
    "visible": true
  }
]
```

- [ ] **Step 4: Commit**

```bash
git add resound-desktop/src-tauri/src/positioning.rs
git commit -m "feat: add window positioning at top-center of screen"
```

---

### Task 13: Build Verification + Cross-Platform Checks

- [ ] **Step 1: Verify Rust build**

```bash
cd resound-desktop
cargo build --manifest-path src-tauri/Cargo.toml
```

Expected: Compiles without errors.

- [ ] **Step 2: Verify frontend build**

```bash
cd resound-desktop
npm run build
```

Expected: Vite builds without errors.

- [ ] **Step 3: Verify full Tauri build**

```bash
cd resound-desktop
npx tauri build
```

Expected: Produces platform binaries.

- [ ] **Step 4: Commit final build configuration**

```bash
git add resound-desktop/
git commit -m "chore: final build configuration and polish"
```
