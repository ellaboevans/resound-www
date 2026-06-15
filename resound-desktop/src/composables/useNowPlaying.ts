import { reactive, onMounted, onUnmounted } from "vue";
import { invoke } from "@tauri-apps/api/core";
import { useSettings } from "./useSettings";

export interface NowPlayingInfo {
  track_title: string;
  artist_name: string;
  album_title: string;
  is_playing: boolean;
  progress: number;
  duration: number;
  volume: number;
  artwork_base64: string;
  source: string;
}

const emptyTrack: NowPlayingInfo = {
  track_title: "",
  artist_name: "",
  album_title: "",
  is_playing: false,
  progress: 0,
  duration: 0,
  volume: 50,
  artwork_base64: "",
  source: "",
};

const state = reactive<{
  current: NowPlayingInfo;
  loading: boolean;
  error: string | null;
}>({
  current: { ...emptyTrack },
  loading: false,
  error: null,
});

let pollInterval: ReturnType<typeof setInterval> | null = null;
let rafId: number | null = null;

let anchorPosSec = 0;
let anchorTime = 0;
let smoothPosSec = 0;
let smoothDurationSec = 0;
let smoothPlaying = false;

let prevTrackTitle = "";
let prevDuration = 0;

function diffUpdate(data: NowPlayingInfo) {
  const c = state.current;
  if (c.track_title !== data.track_title) c.track_title = data.track_title;
  if (c.artist_name !== data.artist_name) c.artist_name = data.artist_name;
  if (c.album_title !== data.album_title) c.album_title = data.album_title;
  if (c.is_playing !== data.is_playing) c.is_playing = data.is_playing;
  if (data.duration > 0 && c.duration !== data.duration) c.duration = data.duration;
  if (c.volume !== data.volume) c.volume = data.volume;
  if (c.source !== data.source) c.source = data.source;
  if (c.artwork_base64 !== data.artwork_base64)
    c.artwork_base64 = data.artwork_base64;
}

function updateProgress() {
  if (smoothPlaying && smoothDurationSec > 0) {
    const elapsed = (performance.now() - anchorTime) / 1000;
    const pos = Math.min(anchorPosSec + elapsed, smoothDurationSec);
    smoothPosSec = pos;
    state.current.progress = pos / smoothDurationSec;
  }
}

let emptyTimeout: ReturnType<typeof setTimeout> | null = null;

function applyBackendData(data: NowPlayingInfo) {
  // Music source filter: if set to "spotify", hide non-Spotify sources
  const settings = useSettings();
  if (settings.state.musicSource === 'spotify') {
    const src = data.source.toLowerCase();
    if (src !== '' && !src.includes('spotify')) {
      data = { ...emptyTrack };
    }
  }

  // When data goes empty while we have a valid track, debounce 3s before
  // clearing. This distinguishes screen lock (transient — music still plays)
  // from app closed (permanent — show empty state).
  if (data.track_title === "" && state.current.track_title !== "") {
    if (!emptyTimeout) {
      emptyTimeout = setTimeout(() => {
        diffUpdate(emptyTrack);
        smoothPlaying = false;
        emptyTimeout = null;
      }, 3000);
    }
    return; // keep current UI until timeout fires or real data returns
  }

  // Valid data — cancel any pending clear
  if (emptyTimeout) {
    clearTimeout(emptyTimeout);
    emptyTimeout = null;
  }

  diffUpdate(data);

  if (data.duration > 0) {
    const newPosSec = data.progress * data.duration;
    const newTrack =
      data.track_title !== prevTrackTitle || data.duration !== prevDuration;
    prevTrackTitle = data.track_title;
    prevDuration = data.duration;

    smoothDurationSec = data.duration;

    if (
      newTrack ||
      (data.is_playing && !smoothPlaying) ||
      newPosSec - smoothPosSec > 2.0
    ) {
      anchorPosSec = newPosSec;
      anchorTime = performance.now();
      smoothPosSec = newPosSec;
    }
  }

  smoothPlaying = data.is_playing;
  updateProgress();
  startStopRaf();
}

function tick() {
  updateProgress();
  rafId = requestAnimationFrame(tick);
}

function startStopRaf() {
  if (!rafId) {
    anchorTime = performance.now();
    rafId = requestAnimationFrame(tick);
  }
}

export function useNowPlaying() {
  async function fetchNowPlaying() {
    state.loading = true;
    try {
      const data = await invoke<NowPlayingInfo>("get_now_playing");
      applyBackendData(data);
      state.error = null;
    } catch (e) {
      state.error = String(e);
    } finally {
      state.loading = false;
    }
  }

  async function playPause() {
    await invoke("play_pause");
    applyBackendData(await invoke<NowPlayingInfo>("get_now_playing"));
  }

  async function nextTrack() {
    await invoke("next_track");
    applyBackendData(await invoke<NowPlayingInfo>("get_now_playing"));
  }

  async function prevTrack() {
    await invoke("prev_track");
    applyBackendData(await invoke<NowPlayingInfo>("get_now_playing"));
  }

  onMounted(async () => {
    const data = await invoke<NowPlayingInfo>("get_now_playing");
    applyBackendData(data);
    pollInterval = setInterval(async () => {
      const data = await invoke<NowPlayingInfo>("get_now_playing");
      applyBackendData(data);
    }, 1000);
  });

  onUnmounted(() => {
    if (pollInterval) clearInterval(pollInterval);
    if (rafId) cancelAnimationFrame(rafId);
  });

  return {
    state,
    fetchNowPlaying,
    playPause,
    nextTrack,
    prevTrack,
  };
}
