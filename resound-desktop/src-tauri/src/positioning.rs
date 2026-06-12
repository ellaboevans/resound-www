use tauri::WebviewWindow;

pub fn center_window_at_top(window: &WebviewWindow) {
    if let Some(monitor) = window.current_monitor().ok().flatten() {
        let screen_size = monitor.size();
        let win_size = window.outer_size().ok().unwrap_or_default();

        let x = ((screen_size.width as f64) - (win_size.width as f64)) / 2.0;
        let y = 24.0;

        let _ = window.set_position(tauri::Position::Physical(
            tauri::PhysicalPosition::new(x as i32, y as i32),
        ));
    }
}
