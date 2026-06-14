use super::{MediaProvider, NowPlayingInfo, VolumeInfo};
use zbus::blocking::Connection;
use zbus::zvariant::Value;
use std::collections::HashMap;

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

fn get_property<'a>(conn: &'a Connection, player_name: &str, property: &str) -> zbus::Result<Value<'a>> {
    conn.call_method(
        Some(player_name),
        "/org/mpris/MediaPlayer2",
        Some("org.freedesktop.DBus.Properties"),
        "Get",
        &("org.mpris.MediaPlayer2.Player", property),
    ).and_then(|m| m.body().deserialize())
}

fn get_playback_status(conn: &Connection, player_name: &str) -> String {
    match get_property(conn, player_name, "PlaybackStatus") {
        Ok(Value::Str(s)) => s.to_string(),
        _ => String::new(),
    }
}

fn get_position_us(conn: &Connection, player_name: &str) -> i64 {
    match get_property(conn, player_name, "Position") {
        Ok(Value::I64(n)) => n,
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

fn get_metadata_string(metadata: &HashMap<String, Value<'_>>, key: &str) -> String {
    metadata.get(key)
        .and_then(|v| v.downcast_ref::<String>().ok())
        .unwrap_or_default()
}

fn get_metadata_artist(metadata: &HashMap<String, Value<'_>>) -> String {
    match metadata.get("xesam:artist") {
        Some(Value::Array(arr)) => {
            let artists: Vec<String> = arr.iter()
                .filter_map(|v| v.downcast_ref::<String>().ok())
                .collect();
            artists.join(", ")
        }
        Some(v) => v.downcast_ref::<String>().ok().unwrap_or_default(),
        None => String::new(),
    }
}

fn get_metadata_i64(metadata: &HashMap<String, Value<'_>>, key: &str) -> i64 {
    metadata.get(key)
        .and_then(|v| v.downcast_ref::<i64>().ok())
        .unwrap_or(0)
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

        let metadata_val = match get_property(conn, &player_name, "Metadata") {
            Ok(v) => v,
            Err(_) => return NowPlayingInfo::default(),
        };

        let metadata: HashMap<String, Value<'_>> = match metadata_val {
            Value::Dict(dict) => {
                let mut map = HashMap::new();
                for (k, v) in dict {
                    if let Ok(key) = k.downcast_ref::<String>() {
                        map.insert(key, v);
                    }
                }
                map
            }
            _ => return NowPlayingInfo::default(),
        };

        let title = get_metadata_string(&metadata, "xesam:title");
        let artist = get_metadata_artist(&metadata);
        let album = get_metadata_string(&metadata, "xesam:album");
        let duration_us = get_metadata_i64(&metadata, "mpris:length");
        let artwork_url = get_metadata_string(&metadata, "mpris:artUrl");

        let status = get_playback_status(conn, &player_name);
        let position_us = get_position_us(conn, &player_name);

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
