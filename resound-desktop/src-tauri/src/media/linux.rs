use super::{MediaProvider, NowPlayingInfo, VolumeInfo};
use zbus::blocking::Connection;
use zbus::zvariant::Value;

pub struct LinuxMediaProvider {
    connection: Option<Connection>,
}

fn find_mpris_players(conn: &Connection) -> Vec<String> {
    let bus = conn.call_method(
        Some("org.freedesktop.DBus"),
        "/org/freedesktop/DBus",
        Some("org.freedesktop.DBus"),
        "ListNames",
        &(),
    );
    let names: Vec<String> = match bus {
        Ok(m) => m.body().deserialize().unwrap_or_default(),
        _ => return vec![],
    };
    names.into_iter().filter(|n| n.contains("org.mpris.MediaPlayer2")).collect()
}

fn unwrap_variant(value: Value<'_>) -> Value<'_> {
    match value {
        Value::Value(inner) => *inner,
        v => v,
    }
}

fn get_playback_status(conn: &Connection, player_name: &str) -> String {
    let msg = conn.call_method(
        Some(player_name),
        "/org/mpris/MediaPlayer2",
        Some("org.freedesktop.DBus.Properties"),
        "Get",
        &("org.mpris.MediaPlayer2.Player", "PlaybackStatus"),
    );
    match msg {
        Ok(m) => {
            let body = m.body();
            let value: Value<'_> = match body.deserialize() {
                Ok(v) => v,
                _ => return String::new(),
            };
            match unwrap_variant(value) {
                Value::Str(s) => s.to_string(),
                _ => String::new(),
            }
        }
        _ => String::new(),
    }
}

fn get_position_us(conn: &Connection, player_name: &str) -> i64 {
    let msg = conn.call_method(
        Some(player_name),
        "/org/mpris/MediaPlayer2",
        Some("org.freedesktop.DBus.Properties"),
        "Get",
        &("org.mpris.MediaPlayer2.Player", "Position"),
    );
    match msg {
        Ok(m) => {
            let body = m.body();
            let value: Value<'_> = match body.deserialize() {
                Ok(v) => v,
                _ => return 0,
            };
            match unwrap_variant(value) {
                Value::I64(n) => n,
                _ => 0,
            }
        }
        _ => 0,
    }
}

fn call_player_method(conn: &Connection, name: &str, method: &str) {
    let _: zbus::Result<()> = conn.call_method(
        Some(name),
        "/org/mpris/MediaPlayer2",
        Some("org.mpris.MediaPlayer2.Player"),
        method,
        &(),
    ).and_then(|_| Ok(()));
}

fn extract_metadata(conn: &Connection, player_name: &str) -> Option<(String, String, String, i64, String)> {
    let msg = conn.call_method(
        Some(player_name),
        "/org/mpris/MediaPlayer2",
        Some("org.freedesktop.DBus.Properties"),
        "Get",
        &("org.mpris.MediaPlayer2.Player", "Metadata"),
    ).ok()?;
    let body = msg.body();
    let value: Value<'_> = body.deserialize().ok()?;

    match unwrap_variant(value) {
        Value::Dict(dict) => {
            let mut title = String::new();
            let mut artist = String::new();
            let mut album = String::new();
            let mut duration = 0i64;
            let mut art_url = String::new();

            for (k, v) in dict {
                let key = match k {
                    Value::Str(s) => s.to_string(),
                    _ => continue,
                };
                match key.as_str() {
                    "xesam:title" => {
                        if let Value::Str(s) = v { title = s.to_string(); }
                    }
                    "xesam:artist" => {
                        match v {
                            Value::Array(arr) => {
                                let artists: Vec<String> = arr.iter()
                                    .filter_map(|v| match v {
                                        Value::Str(s) => Some(s.to_string()),
                                        _ => None,
                                    })
                                    .collect();
                                artist = artists.join(", ");
                            }
                            Value::Str(s) => artist = s.to_string(),
                            _ => {}
                        }
                    }
                    "xesam:album" => {
                        if let Value::Str(s) = v { album = s.to_string(); }
                    }
                    "mpris:length" => {
                        if let Value::I64(n) = v { duration = n; }
                    }
                    "mpris:artUrl" => {
                        if let Value::Str(s) = v { art_url = s.to_string(); }
                    }
                    _ => {}
                }
            }

            Some((title, artist, album, duration, art_url))
        }
        _ => None,
    }
}

impl LinuxMediaProvider {
    pub fn new() -> Self {
        let conn = Connection::session().ok();
        Self { connection: conn }
    }

    fn best_player(&self) -> Option<(String, &Connection)> {
        let conn = self.connection.as_ref()?;
        let players = find_mpris_players(conn);
        let name = players.into_iter().next()?;
        Some((name, conn))
    }
}

impl MediaProvider for LinuxMediaProvider {
    fn current_track(&self) -> NowPlayingInfo {
        let (player_name, conn) = match self.best_player() {
            Some(p) => p,
            None => return NowPlayingInfo::default(),
        };

        let status = get_playback_status(conn, &player_name);
        let position_us = get_position_us(conn, &player_name);

        let (title, artist, album, duration_us, artwork_url) = match extract_metadata(conn, &player_name) {
            Some(v) => v,
            None => return NowPlayingInfo::default(),
        };

        let duration_secs = duration_us as f64 / 1_000_000.0;
        let position_secs = position_us as f64 / 1_000_000.0;

        let artwork_b64 = fetch_artwork_base64(&artwork_url);

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
        let (player_name, conn) = match self.best_player() {
            Some(p) => p,
            None => return,
        };
        call_player_method(conn, &player_name, "PlayPause");
    }

    fn next_track(&self) {
        let (player_name, conn) = match self.best_player() {
            Some(p) => p,
            None => return,
        };
        call_player_method(conn, &player_name, "Next");
    }

    fn prev_track(&self) {
        let (player_name, conn) = match self.best_player() {
            Some(p) => p,
            None => return,
        };
        call_player_method(conn, &player_name, "Previous");
    }

    fn volume(&self) -> VolumeInfo {
        VolumeInfo { level: 0.5, muted: false }
    }

    fn set_volume(&self, _level: f64) {}
}

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
