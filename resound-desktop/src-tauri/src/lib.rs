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
