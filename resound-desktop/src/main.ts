import { createApp } from 'vue'
import App from './App.vue'
import { useVolume } from './composables/useVolume'
import { useVolumeOverlay } from './composables/useVolumeOverlay'
import { useSettings } from './composables/useSettings'
import './assets/styles.css'

const app = createApp(App)
app.mount('#app')

useVolume().init()
useVolumeOverlay().init()
useSettings().load()
