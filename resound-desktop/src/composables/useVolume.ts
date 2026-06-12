import { reactive } from 'vue'
import { invoke } from '@tauri-apps/api/core'
import { listen } from '@tauri-apps/api/event'

export interface VolumeInfo {
  level: number
  muted: boolean
}

const state = reactive<{
  level: number
  muted: boolean
}>({
  level: 50,
  muted: false,
})

let unlisten: (() => void) | null = null

export function useVolume() {
  async function fetchVolume() {
    try {
      const info = await invoke<VolumeInfo>('get_volume')
      state.level = Math.round(info.level * 100)
      state.muted = info.muted
    } catch {}
  }

  async function setVolume(level: number) {
    state.level = level
    try {
      await invoke('set_volume', { level: level / 100 })
    } catch {}
  }

  async function init() {
    await fetchVolume()
    unlisten = await listen<VolumeInfo>('volume-changed', (event) => {
      state.level = Math.round(event.payload.level * 100)
      state.muted = event.payload.muted
    })
  }

  function cleanup() {
    if (unlisten) {
      unlisten()
      unlisten = null
    }
  }

  return {
    state,
    fetchVolume,
    setVolume,
    init,
    cleanup,
  }
}
