use tauri::WebviewWindow;

pub fn center_window_at_top(window: &WebviewWindow) {
    if let Some(monitor) = window.current_monitor().ok().flatten() {
        let screen_size = monitor.size();
        let win_size = window.outer_size().ok().unwrap_or_default();
        let scale = monitor.scale_factor();

        let x = ((screen_size.width as f64) - (win_size.width as f64)) / 2.0 / scale;
        let y = 24.0;

        let _ = window.set_position(tauri::Position::Logical(
            tauri::LogicalPosition::new(x, y),
        ));
    }
}
