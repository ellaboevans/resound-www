use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex, atomic::{AtomicBool, Ordering}};
use std::thread;
use std::time::Duration;

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct NowPlayingInfo {
    pub track_title: String,
    pub artist_name: String,
    pub album_title: String,
    pub is_playing: bool,
    pub progress: f64,
    pub duration: f64,
    pub volume: i32,
    pub artwork_base64: String,
    pub source: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct VolumeInfo {
    pub level: f64,
    pub muted: bool,
}

pub trait MediaProvider: Send + Sync {
    fn current_track(&self) -> NowPlayingInfo;
    fn has_media_session(&self) -> bool { true }
    fn play_pause(&self);
    fn next_track(&self);
    fn prev_track(&self);
    fn volume(&self) -> VolumeInfo;
    fn set_volume(&self, level: f64);
}

#[cfg(target_os = "windows")]
mod windows;
#[cfg(target_os = "linux")]
mod linux;
#[cfg(target_os = "macos")]
mod macos;

#[cfg(target_os = "windows")]
use windows::WindowsMediaProvider as PlatformMediaProvider;
#[cfg(target_os = "linux")]
use linux::LinuxMediaProvider as PlatformMediaProvider;
#[cfg(target_os = "macos")]
use macos::MacosMediaProvider as PlatformMediaProvider;

pub struct MediaManager {
    provider: Arc<PlatformMediaProvider>,
    cached_track: Arc<Mutex<NowPlayingInfo>>,
    _running: Arc<AtomicBool>,
}

impl MediaManager {
    pub fn new() -> Self {
        let provider = Arc::new(PlatformMediaProvider::new());
        let cached_track = Arc::new(Mutex::new(NowPlayingInfo::default()));
        let running = Arc::new(AtomicBool::new(true));

        let bg_provider = provider.clone();
        let bg_cache = cached_track.clone();
        let bg_running = running.clone();

        let mut prev_key = (String::new(), String::new());
        let mut cached_artwork = String::new();

        thread::spawn(move || {
            while bg_running.load(Ordering::Relaxed) {
                let mut info = bg_provider.current_track();
                let key = (info.track_title.clone(), info.artist_name.clone());
                if key == prev_key && !cached_artwork.is_empty() {
                    info.artwork_base64 = cached_artwork.clone();
                } else {
                    prev_key = key;
                    cached_artwork = info.artwork_base64.clone();
                }
                if let Ok(mut cache) = bg_cache.lock() {
                    *cache = info;
                }
                thread::sleep(Duration::from_secs(1));
            }
        });

        Self {
            provider,
            cached_track,
            _running: running,
        }
    }

    pub fn get_current_track(&self) -> NowPlayingInfo {
        self.cached_track.lock().map(|c| c.clone()).unwrap_or_default()
    }

    pub fn play_pause(&self) {
        self.provider.play_pause();
    }

    pub fn next_track(&self) {
        self.provider.next_track();
    }

    pub fn prev_track(&self) {
        self.provider.prev_track();
    }

    pub fn volume(&self) -> VolumeInfo {
        self.provider.volume()
    }

    pub fn set_volume(&self, level: f64) {
        self.provider.set_volume(level);
    }
}
