import { reactive } from 'vue'
import { invoke } from '@tauri-apps/api/core'

interface Settings {
  autoHide: boolean
  launchAtLogin: boolean
  musicSource: 'automatic' | 'spotify'
}

const state = reactive<Settings>({
  autoHide: true,
  launchAtLogin: false,
  musicSource: 'automatic',
})

export function useSettings() {
  async function load() {
    try {
      const s = await invoke<Settings>('get_settings')
      Object.assign(state, s)
    } catch {}
  }

  async function save() {
    try {
      const diag = await invoke<string>('set_settings', { settings: { ...state } })
      console.log('[resound] set_settings:', diag)
    } catch (e) {
      console.error('[resound] set_settings failed:', e)
    }
  }

  function setAutoHide(v: boolean) {
    state.autoHide = v
    save()
  }

  function setLaunchAtLogin(v: boolean) {
    state.launchAtLogin = v
    save()
  }

  function setMusicSource(v: Settings['musicSource']) {
    state.musicSource = v
    save()
  }

  return { state, load, save, setAutoHide, setLaunchAtLogin, setMusicSource }
}
