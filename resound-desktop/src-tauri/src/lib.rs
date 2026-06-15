use std::sync::Mutex;
use serde::{Deserialize, Serialize};
use tauri::Manager;
use tauri_plugin_autostart::ManagerExt;

mod media;
mod positioning;
mod tray;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
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

pub struct AppState {
    pub media_manager: media::MediaManager,
    pub settings: Mutex<AppSettings>,
}

#[tauri::command]
fn get_now_playing(state: tauri::State<'_, Mutex<AppState>>) -> media::NowPlayingInfo {
    if let Some(app_state) = state.lock().ok() {
        app_state.media_manager.get_current_track()
    } else {
        media::NowPlayingInfo::default()
    }
}

#[tauri::command]
fn play_pause(state: tauri::State<'_, Mutex<AppState>>) {
    if let Some(app_state) = state.lock().ok() {
        app_state.media_manager.play_pause();
    }
}

#[tauri::command]
fn next_track(state: tauri::State<'_, Mutex<AppState>>) {
    if let Some(app_state) = state.lock().ok() {
        app_state.media_manager.next_track();
    }
}

#[tauri::command]
fn prev_track(state: tauri::State<'_, Mutex<AppState>>) {
    if let Some(app_state) = state.lock().ok() {
        app_state.media_manager.prev_track();
    }
}

#[tauri::command]
fn get_volume(state: tauri::State<'_, Mutex<AppState>>) -> media::VolumeInfo {
    if let Some(app_state) = state.lock().ok() {
        app_state.media_manager.volume()
    } else {
        media::VolumeInfo::default()
    }
}

#[tauri::command]
fn set_volume(level: f64, state: tauri::State<'_, Mutex<AppState>>) {
    if let Some(app_state) = state.lock().ok() {
        app_state.media_manager.set_volume(level);
    }
}

#[tauri::command]
fn get_settings(state: tauri::State<'_, Mutex<AppState>>, app: tauri::AppHandle) -> AppSettings {
    let mut settings = AppSettings::default();
    if let Some(app_state) = state.lock().ok() {
        if let Ok(s) = app_state.settings.lock() {
            settings = s.clone();
        }
    }
    let autolaunch = app.autolaunch();
    settings.launch_at_login = autolaunch.is_enabled().unwrap_or(false);
    settings
}

#[tauri::command]
fn set_settings(settings: AppSettings, state: tauri::State<'_, Mutex<AppState>>, app: tauri::AppHandle) -> Result<String, String> {
    let launch_at_login = settings.launch_at_login;
    if let Some(app_state) = state.lock().ok() {
        if let Ok(mut s) = app_state.settings.lock() {
            *s = settings;
        }
    }
    let autolaunch = app.autolaunch();
    let current_exe = std::env::current_exe().map(|p| p.display().to_string()).unwrap_or_default();
    let already = autolaunch.is_enabled().unwrap_or(false);
    let result: Result<String, String> = if launch_at_login {
        autolaunch.enable().map(|_| "enabled".into()).map_err(|e| format!("enable failed: {e}"))
    } else {
        autolaunch.disable().map(|_| "disabled".into()).map_err(|e| format!("disable failed: {e}"))
    };
    let diag = format!(
        "launch_at_login={launch_at_login}, was_already={already}, result={result:?}, exe={current_exe}"
    );
    eprintln!("[resound] set_settings: {diag}");
    Ok(diag)
}

#[tauri::command]
fn set_window_size(width: u32, height: u32, window: tauri::WebviewWindow) {
    let _ = window.set_size(tauri::Size::Logical(
        tauri::LogicalSize::new(width as f64, height as f64),
    ));
}

#[tauri::command]
fn ensure_on_top(window: tauri::WebviewWindow) {
    let _ = window.set_always_on_top(true);
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_autostart::init(tauri_plugin_autostart::MacosLauncher::LaunchAgent, None))
        .manage(Mutex::new(AppState {
            media_manager: media::MediaManager::new(),
            settings: Mutex::new(AppSettings::default()),
        }))
        .invoke_handler(tauri::generate_handler![
            get_now_playing,
            play_pause,
            next_track,
            prev_track,
            get_volume,
            set_volume,
            get_settings,
            set_settings,
            set_window_size,
            ensure_on_top,
        ])
        .setup(|app| {
            let _ = tray::setup_tray(app.handle());
            if let Some(window) = app.get_webview_window("main") {
                positioning::center_window_at_top(&window);
                let _ = window.set_always_on_top(true);

                // Re-position after window is mapped (fixes Linux where
                // set_position during setup can be silently ignored)
                let win = window.clone();
                std::thread::spawn(move || {
                    std::thread::sleep(std::time::Duration::from_millis(200));
                    positioning::center_window_at_top(&win);
                });
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
