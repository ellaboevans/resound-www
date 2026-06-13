import { createApp } from 'vue'
import App from './App.vue'
import { useSettings } from './composables/useSettings'
import './assets/styles.css'

const app = createApp(App)
app.mount('#app')

useSettings().load()
