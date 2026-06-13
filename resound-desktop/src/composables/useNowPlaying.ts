import { reactive, onMounted, onUnmounted } from 'vue'
import { invoke } from '@tauri-apps/api/core'
import { listen } from '@tauri-apps/api/event'

export interface NowPlayingInfo {
  track_title: string
  artist_name: string
  album_title: string
  is_playing: boolean
  progress: number
  duration: number
  volume: number
  artwork_base64: string
  source: string
}

const emptyTrack: NowPlayingInfo = {
  track_title: '',
  artist_name: '',
  album_title: '',
  is_playing: false,
  progress: 0,
  duration: 0,
  volume: 50,
  artwork_base64: '',
  source: '',
}

const state = reactive<{
  current: NowPlayingInfo
  loading: boolean
  error: string | null
}>({
  current: { ...emptyTrack },
  loading: false,
  error: null,
})

let unlisten: (() => void) | null = null
let pollInterval: ReturnType<typeof setInterval> | null = null
let rafId: number | null = null
let smoothPosSec = 0
let smoothDurationSec = 0
let smoothPlaying = false
let smoothAnchor = 0

function applyBackendData(data: NowPlayingInfo) {
  smoothPosSec = data.progress * data.duration
  smoothDurationSec = data.duration
  smoothPlaying = data.is_playing
  smoothAnchor = performance.now()
  state.current = { ...data, progress: smoothDurationSec > 0 ? smoothPosSec / smoothDurationSec : 0 }
}

function tick(now: number) {
  if (smoothPlaying && smoothDurationSec > 0) {
    const elapsed = (now - smoothAnchor) / 1000
    smoothPosSec = Math.min(smoothPosSec + elapsed, smoothDurationSec)
    smoothAnchor = now
    const pct = smoothPosSec / smoothDurationSec
    if (Math.abs(state.current.progress - pct) > 0.001) {
      state.current.progress = pct
    }
  }
  rafId = requestAnimationFrame(tick)
}

export function useNowPlaying() {
  async function fetchNowPlaying() {
    state.loading = true
    try {
      const data = await invoke<NowPlayingInfo>('get_now_playing')
      applyBackendData(data)
      state.error = null
    } catch (e) {
      state.error = String(e)
    } finally {
      state.loading = false
    }
  }

  async function playPause() {
    await invoke('play_pause')
    applyBackendData(await invoke<NowPlayingInfo>('get_now_playing'))
  }

  async function nextTrack() {
    await invoke('next_track')
    applyBackendData(await invoke<NowPlayingInfo>('get_now_playing'))
  }

  async function prevTrack() {
    await invoke('prev_track')
    applyBackendData(await invoke<NowPlayingInfo>('get_now_playing'))
  }

  onMounted(async () => {
    const data = await invoke<NowPlayingInfo>('get_now_playing')
    applyBackendData(data)
    pollInterval = setInterval(async () => {
      const data = await invoke<NowPlayingInfo>('get_now_playing')
      applyBackendData(data)
    }, 1000)
    rafId = requestAnimationFrame(tick)
    unlisten = await listen<NowPlayingInfo>('now-playing-changed', (event) => {
      applyBackendData(event.payload)
    })
  })

  onUnmounted(() => {
    if (pollInterval) clearInterval(pollInterval)
    if (rafId) cancelAnimationFrame(rafId)
    if (unlisten) unlisten()
  })

  return {
    state,
    fetchNowPlaying,
    playPause,
    nextTrack,
    prevTrack,
  }
}
