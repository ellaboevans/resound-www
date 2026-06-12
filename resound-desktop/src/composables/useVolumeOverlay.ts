import { reactive, onUnmounted } from 'vue'
import { listen } from '@tauri-apps/api/event'

export interface OverlayState {
  visible: boolean
  level: number
  muted: boolean
  mode: 'volume' | 'brightness'
}

const state = reactive<OverlayState>({
  visible: false,
  level: 0.5,
  muted: false,
  mode: 'volume',
})

let hideTimer: ReturnType<typeof setTimeout> | null = null
let unlisten: (() => void) | null = null

export function useVolumeOverlay() {
  function show(level: number, muted: boolean, mode: 'volume' | 'brightness' = 'volume') {
    state.level = level
    state.muted = muted
    state.mode = mode
    state.visible = true

    if (hideTimer) clearTimeout(hideTimer)
    hideTimer = setTimeout(() => {
      state.visible = false
    }, 1000)
  }

  function hide() {
    state.visible = false
    if (hideTimer) clearTimeout(hideTimer)
  }

  async function init() {
    unlisten = await listen<{ level: number; muted: boolean }>('volume-changed', (event) => {
      show(event.payload.level, event.payload.muted)
    })
  }

  onUnmounted(() => {
    if (unlisten) {
      unlisten()
      unlisten = null
    }
  })

  return { state, show, hide, init }
}
