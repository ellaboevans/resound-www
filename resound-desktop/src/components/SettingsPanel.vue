<script setup lang="ts">
import { ref, inject, watch, type Ref } from 'vue'
import { useSettings } from '../composables/useSettings'
import { Settings } from "@lucide/vue";

const settings = useSettings()
const open = ref(false)

const expanded = inject<Ref<boolean>>('expanded')
if (expanded) {
  watch(expanded, (v) => { if (!v) open.value = false })
}
</script>

<template>
  <div class="settings-wrapper">
    <button class="gear" @click="open = !open"><Settings :size="16" /></button>
    <Transition name="slide">
      <div class="panel" v-if="open">
        <label class="row">
          <span>Auto-hide</span>
          <input type="checkbox" :checked="settings.state.autoHide" @change="settings.setAutoHide(($event.target as HTMLInputElement).checked)" />
        </label>
        <label class="row">
          <span>Launch at login</span>
          <input type="checkbox" :checked="settings.state.launchAtLogin" @change="settings.setLaunchAtLogin(($event.target as HTMLInputElement).checked)" />
        </label>
        <label class="row">
          <span>Source</span>
          <select :value="settings.state.musicSource" @change="settings.setMusicSource(($event.target as HTMLSelectElement).value as any)">
            <option value="automatic">Automatic</option>
            <option value="spotify">Spotify only</option>
          </select>
        </label>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.settings-wrapper {
  position: relative;
}

.gear {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.3);
  font-size: 14px;
  cursor: pointer;
  padding: 4px 8px;
  -webkit-app-region: no-drag;
  display: flex;
  align-items: center;
  justify-content: center;
}

.gear:hover {
  opacity: 0.7;
}

.panel {
  position: absolute;
  top: 100%;
  right: 0;
  background: #111;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 10px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  min-width: 180px;
  margin-top: 4px;
  z-index: 20;
}

.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 12px;
  gap: 12px;
  cursor: pointer;
}

.row input[type="checkbox"] {
  accent-color: white;
}

.row select {
  background: #222;
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: white;
  font-size: 11px;
  padding: 2px 6px;
  border-radius: 4px;
}

.slide-enter-active,
.slide-leave-active {
  transition: opacity 0.12s ease, transform 0.12s ease;
}

.slide-enter-from,
.slide-leave-to {
  opacity: 0;
  transform: translateY(4px);
}
</style>
