use tauri::WebviewWindow;

pub fn center_window_at_top(window: &WebviewWindow) {
    let monitor = window.current_monitor()
        .ok()
        .flatten()
        .or_else(|| {
            window.available_monitors()
                .ok()?
                .into_iter()
                .next()
        });

    if let Some(monitor) = monitor {
        let screen_size = monitor.size();
        let scale = monitor.scale_factor();

        let win_w = window.outer_size()
            .ok()
            .filter(|s| s.width > 0)
            .map(|s| s.width as f64)
            .unwrap_or(280.0 * scale);

        let x = ((screen_size.width as f64) - win_w) / 2.0 / scale;
        let y = 24.0;

        let _ = window.set_position(tauri::Position::Logical(
            tauri::LogicalPosition::new(x, y),
        ));
    }
}
