use super::{MediaProvider, NowPlayingInfo, VolumeInfo};

pub struct MacosMediaProvider;

impl MacosMediaProvider {
    pub fn new() -> Self {
        Self
    }
}

impl MediaProvider for MacosMediaProvider {
    fn current_track(&self) -> NowPlayingInfo {
        NowPlayingInfo::default()
    }

    fn play_pause(&self) {}

    fn next_track(&self) {}

    fn prev_track(&self) {}

    fn volume(&self) -> VolumeInfo {
        VolumeInfo {
            level: 0.5,
            muted: false,
        }
    }

    fn set_volume(&self, _level: f64) {}
}
