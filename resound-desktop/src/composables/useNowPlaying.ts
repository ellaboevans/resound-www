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

export function useNowPlaying() {
  async function fetch() {
    state.loading = true
    try {
      state.current = await invoke<NowPlayingInfo>('get_now_playing')
      state.error = null
    } catch (e) {
      state.error = String(e)
    } finally {
      state.loading = false
    }
  }

  async function playPause() {
    await invoke('play_pause')
    await fetch()
  }

  async function nextTrack() {
    await invoke('next_track')
    await fetch()
  }

  async function prevTrack() {
    await invoke('prev_track')
    await fetch()
  }

  onMounted(async () => {
    await fetch()
    pollInterval = setInterval(fetch, 1000)
    unlisten = await listen<NowPlayingInfo>('now-playing-changed', (event) => {
      state.current = event.payload
    })
  })

  onUnmounted(() => {
    if (pollInterval) clearInterval(pollInterval)
    if (unlisten) unlisten()
  })

  return {
    state,
    fetch,
    playPause,
    nextTrack,
    prevTrack,
  }
}
