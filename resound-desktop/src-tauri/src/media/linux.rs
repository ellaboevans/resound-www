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

fn get_playback_status(conn: &Connection, name: &str) -> String {
    let proxy_path = "/org/mpris/MediaPlayer2";
    conn.call_method(
        Some(name),
        proxy_path,
        Some("org.mpris.MediaPlayer2.Player"),
        "PlaybackStatus",
        &(),
    ).and_then(|r| r.body().deserialize()).unwrap_or_default()
}

fn get_position(conn: &Connection, name: &str) -> i64 {
    let proxy_path = "/org/mpris/MediaPlayer2";
    conn.call_method(
        Some(name),
        proxy_path,
        Some("org.mpris.MediaPlayer2.Player"),
        "Position",
        &(),
    ).and_then(|r| r.body().deserialize()).unwrap_or(0)
}

fn call_player_method(conn: &Connection, name: &str, method: &str) {
    let proxy_path = "/org/mpris/MediaPlayer2";
    let _: zbus::Result<()> = conn.call_method(
        Some(name),
        proxy_path,
        Some("org.mpris.MediaPlayer2.Player"),
        method,
        &(),
    ).and_then(|_| Ok(()));
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

        let proxy_path = "/org/mpris/MediaPlayer2";
        let player_iface = "org.mpris.MediaPlayer2.Player";

        let msg = match conn.call_method(
            Some(player_name.as_str()), proxy_path,
            Some(player_iface), "Metadata", &(),
        ) {
            Ok(m) => m,
            Err(_) => return NowPlayingInfo::default(),
        };

        let body = msg.body();
        let metadata: HashMap<String, Value<'_>> = match body.deserialize() {
            Ok(m) => m,
            Err(_) => return NowPlayingInfo::default(),
        };

        let title = metadata.get("xesam:title")
            .and_then(|v| v.downcast_ref::<String>().ok())
            .unwrap_or_default();

        let artist = match metadata.get("xesam:artist") {
            Some(v) => v.downcast_ref::<String>().ok().unwrap_or_default(),
            None => String::new(),
        };

        let album = metadata.get("xesam:album")
            .and_then(|v| v.downcast_ref::<String>().ok())
            .unwrap_or_default();

        let duration_us = metadata.get("mpris:length")
            .and_then(|v| v.downcast_ref::<i64>().ok())
            .unwrap_or(0);

        let artwork_url = metadata.get("mpris:artUrl")
            .and_then(|v| v.downcast_ref::<String>().ok())
            .unwrap_or_default();

        let status = get_playback_status(conn, &player_name);
        let position_us = get_position(conn, &player_name);

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
