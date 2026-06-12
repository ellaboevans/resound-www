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

        let artwork_url = metadata.get("mpris:artUrl")
            .and_then(|v| v.downcast_ref::<String>())
            .cloned()
            .unwrap_or_default();

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
