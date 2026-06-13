use super::{MediaProvider, NowPlayingInfo, VolumeInfo};
use windows::Media::Control::{
    GlobalSystemMediaTransportControlsSession,
    GlobalSystemMediaTransportControlsSessionManager,
    GlobalSystemMediaTransportControlsSessionPlaybackStatus,
};
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

    /// True when Windows reports any active media session (an app is registered
    /// with GSMTC). False when every media app is closed — caller should show
    /// the empty/stopped state rather than preserving a stale cached track.
    pub fn has_active_session(&self) -> bool {
        self.ensure_manager()
            .and_then(|m| m.GetCurrentSession().ok())
            .is_some()
    }

    fn get_current_session(&self) -> Option<GlobalSystemMediaTransportControlsSession> {
        let manager = self.ensure_manager()?;
        let session = manager.GetCurrentSession().ok()?;
        // Verify the session is alive by checking its playback info
        if session.GetPlaybackInfo().is_err() {
            // Session went stale (screen lock / sleep). Clear cached manager
            // so the next poll re-acquires a fresh one.
            if let Ok(mut guard) = self.manager.lock() {
                *guard = None;
            }
            return None;
        }
        Some(session)
    }

    fn ensure_manager(&self) -> Option<GlobalSystemMediaTransportControlsSessionManager> {
        {
            let guard = self.manager.lock().ok()?;
            if let Some(ref mgr) = *guard {
                return Some(mgr.clone());
            }
        }
        let mgr = GlobalSystemMediaTransportControlsSessionManager::RequestAsync()
            .ok()?
            .get()
            .ok()?;
        let mut guard = self.manager.lock().ok()?;
        *guard = Some(mgr.clone());
        Some(mgr)
    }
}

impl MediaProvider for WindowsMediaProvider {
    fn current_track(&self) -> NowPlayingInfo {
        let session = match self.get_current_session() {
            Some(s) => s,
            None => return NowPlayingInfo::default(),
        };

        let display_props = match session.TryGetMediaPropertiesAsync().ok().and_then(|op| op.get().ok()) {
            Some(props) => props,
            _ => return NowPlayingInfo::default(),
        };

        let title = display_props.Title().unwrap_or_default().to_string();
        let artist = display_props.Artist().unwrap_or_default().to_string();
        let album = display_props.AlbumTitle().unwrap_or_default().to_string();

        let playback = session.GetPlaybackInfo().ok();
        let is_playing = playback
            .and_then(|p| p.PlaybackStatus().ok())
            .map(|s| s == GlobalSystemMediaTransportControlsSessionPlaybackStatus::Playing)
            .unwrap_or(false);

        let timeline_props = session.GetTimelineProperties().ok();
        let (duration, position) = if let Some(tp) = timeline_props {
            let pos = tp.Position().ok()
                .map(|ts| ts.Duration as f64 / 10_000_000.0)
                .unwrap_or(0.0);
            let dur = {
                let end = tp.EndTime().ok().map(|ts| ts.Duration).unwrap_or(0);
                let start = tp.StartTime().ok().map(|ts| ts.Duration).unwrap_or(0);
                if end > start { (end - start) as f64 / 10_000_000.0 } else { 0.0 }
            };
            (dur, pos)
        } else {
            (0.0, 0.0)
        };

        let artwork_base64 = (|| -> Option<String> {
            use windows::Storage::Streams::DataReader;

            let thumbnail = display_props.Thumbnail().ok()?;
            let stream = thumbnail.OpenReadAsync().ok().and_then(|op| op.get().ok())?;

            let reader = DataReader::CreateDataReader(&stream).ok()?;
            let s = stream.Size().ok()?;
            let size = u32::try_from(s).ok().filter(|&s| s > 0 && s <= 5_000_000)?;

            if let Ok(op) = reader.LoadAsync(size) { let _ = op.get(); }
            let mut buffer = vec![0u8; size as usize];
            reader.ReadBytes(&mut buffer).ok()?;

            use base64::Engine;
            Some(base64::engine::general_purpose::STANDARD.encode(&buffer))
        })().unwrap_or_default();

        NowPlayingInfo {
            track_title: title,
            artist_name: artist,
            album_title: album,
            is_playing,
            progress: if duration > 0.0 { position / duration } else { 0.0 },
            duration,
            volume: 50,
            artwork_base64,
            source: "Windows.Media.Control".into(),
        }
    }

    fn has_media_session(&self) -> bool {
        self.ensure_manager()
            .and_then(|m| m.GetCurrentSession().ok())
            .is_some()
    }

    fn play_pause(&self) {
        if let Some(session) = self.get_current_session() {
            let status = session
                .GetPlaybackInfo()
                .ok()
                .and_then(|p| p.PlaybackStatus().ok());
            match status {
                Some(GlobalSystemMediaTransportControlsSessionPlaybackStatus::Playing) => {
                    if let Ok(op) = session.TryPauseAsync() { let _ = op.get(); }
                }
                _ => {
                    if let Ok(op) = session.TryPlayAsync() { let _ = op.get(); }
                }
            }
        }
    }

    fn next_track(&self) {
        if let Some(session) = self.get_current_session() {
            if let Ok(op) = session.TrySkipNextAsync() { let _ = op.get(); }
        }
    }

    fn prev_track(&self) {
        if let Some(session) = self.get_current_session() {
            if let Ok(op) = session.TrySkipPreviousAsync() { let _ = op.get(); }
        }
    }

    fn volume(&self) -> VolumeInfo {
        VolumeInfo {
            level: 0.5,
            muted: false,
        }
    }

    fn set_volume(&self, _level: f64) {}
}
