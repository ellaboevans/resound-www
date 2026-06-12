use serde::{Deserialize, Serialize};

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
    provider: PlatformMediaProvider,
}

impl MediaManager {
    pub fn new() -> Self {
        Self {
            provider: PlatformMediaProvider::new(),
        }
    }

    pub fn get_current_track(&self) -> NowPlayingInfo {
        self.provider.current_track()
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
