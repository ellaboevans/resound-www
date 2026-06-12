use super::{MediaProvider, NowPlayingInfo, VolumeInfo};
use windows::Media::Control::{
    GlobalSystemMediaTransportControlsSession,
    GlobalSystemMediaTransportControlsSessionManager,
    GlobalSystemMediaTransportControlsSessionPlaybackStatus,
};
use windows::Foundation::TimeSpan;
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

    fn get_current_session(&self) -> Option<GlobalSystemMediaTransportControlsSession> {
        let manager = self.ensure_manager()?;
        manager.GetCurrentSession().ok()
    }

    fn ensure_manager(&self) -> Option<GlobalSystemMediaTransportControlsSessionManager> {
        let mut guard = self.manager.lock().ok()?;
        if guard.is_none() {
            *guard = futures::executor::block_on(
                GlobalSystemMediaTransportControlsSessionManager::RequestAsync(),
            )
            .ok();
        }
        guard.clone()
    }
}

impl MediaProvider for WindowsMediaProvider {
    fn current_track(&self) -> NowPlayingInfo {
        let session = match self.get_current_session() {
            Some(s) => s,
            None => return NowPlayingInfo::default(),
        };

        let display_props =
            match futures::executor::block_on(session.TryGetMediaPropertiesAsync()) {
                Ok(props) => props,
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
            let dur = tp.Duration().unwrap_or_default();
            let pos = tp.Position().unwrap_or_default();
            (timespan_to_secs(dur), timespan_to_secs(pos))
        } else {
            (0.0, 0.0)
        };

        let artwork_base64 = fetch_artwork_base64(&display_props);

        NowPlayingInfo {
            track_title: title,
            artist_name: artist,
            album_title: album,
            is_playing,
            progress: if duration > 0.0 {
                position / duration
            } else {
                0.0
            },
            duration,
            volume: 50,
            artwork_base64,
            source: "Windows.Media.Control".into(),
        }
    }

    fn play_pause(&self) {
        if let Some(session) = self.get_current_session() {
            let status = session
                .GetPlaybackInfo()
                .ok()
                .and_then(|p| p.PlaybackStatus().ok());
            match status {
                Some(GlobalSystemMediaTransportControlsSessionPlaybackStatus::Playing) => {
                    let _ = futures::executor::block_on(session.TryPauseAsync());
                }
                _ => {
                    let _ = futures::executor::block_on(session.TryPlayAsync());
                }
            }
        }
    }

    fn next_track(&self) {
        if let Some(session) = self.get_current_session() {
            let _ = futures::executor::block_on(session.TrySkipNextAsync());
        }
    }

    fn prev_track(&self) {
        if let Some(session) = self.get_current_session() {
            let _ = futures::executor::block_on(session.TrySkipPreviousAsync());
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

fn timespan_to_secs(ts: TimeSpan) -> f64 {
    ts.Duration as f64 / 10_000_000.0
}

fn fetch_artwork_base64(
    props: &windows::Media::MediaProperties::MediaItemDisplayProperties,
) -> String {
    use windows::Storage::Streams::{DataReader, InputStreamOptions};

    let thumbnail = match props.Thumbnail().ok().and_then(|t| t.ok()) {
        Some(t) => t,
        None => return String::new(),
    };

    let stream = match futures::executor::block_on(thumbnail.OpenReadAsync()).ok() {
        Some(s) => s,
        None => return String::new(),
    };

    let reader = match DataReader::CreateDataReader(&stream) {
        Ok(r) => r,
        _ => return String::new(),
    };

    let size = match u32::try_from(stream.Size()) {
        Ok(s) if s > 0 && s <= 5_000_000 => s,
        _ => return String::new(),
    };

    let _ = futures::executor::block_on(reader.LoadAsync(size)).ok();
    let mut buffer = vec![0u8; size as usize];
    if reader.ReadBytes(&mut buffer).is_err() {
        return String::new();
    }

    use base64::Engine;
    base64::engine::general_purpose::STANDARD.encode(&buffer)
}
