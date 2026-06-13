<script setup lang="ts">
import { ref, watch } from 'vue'
import { invoke } from '@tauri-apps/api/core'
import Pill from './components/Pill.vue'
import ExpandedPanel from './components/ExpandedPanel.vue'
import SettingsPanel from './components/SettingsPanel.vue'

const expanded = ref(false)
const COLLAPSED_H = 48
const EXPANDED_H = 280
const W = 280

async function resize(h: number) {
  try { await invoke('set_window_size', { width: W, height: h }) }
  catch {}
}

watch(expanded, (v) => resize(v ? EXPANDED_H : COLLAPSED_H), { immediate: false })
</script>

<template>
  <div class="window" @mouseenter="expanded = true" @mouseleave="expanded = false">
    <div class="container" :class="{ expanded }">
      <Pill />
      <Transition name="panel">
        <div class="panel-wrap" v-if="expanded">
          <div class="divider"></div>
          <ExpandedPanel />
        </div>
      </Transition>
    </div>
    <div class="settings-pos">
      <SettingsPanel />
    </div>
  </div>
</template>

<style scoped>
.window {
  width: 100vw;
  height: 100vh;
  background: transparent;
  position: relative;
}

.container {
  background: rgba(12, 12, 12, 0.95);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 16px;
  overflow: hidden;
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  min-width: 200px;
  max-width: 320px;
  transition: all 0.2s ease;
}

.container.expanded {
  min-width: 280px;
}

.panel-wrap {
  overflow: hidden;
}

.divider {
  height: 1px;
  background: rgba(255, 255, 255, 0.06);
  margin: 0;
}

.settings-pos {
  position: absolute;
  top: 4px;
  right: 4px;
  z-index: 10;
}

.panel-enter-active,
.panel-leave-active {
  transition: max-height 0.2s ease, opacity 0.15s ease;
  max-height: 300px;
}

.panel-enter-from,
.panel-leave-to {
  max-height: 0;
  opacity: 0;
}
</style>
