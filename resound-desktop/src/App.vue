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

let collapseTimer: ReturnType<typeof setTimeout> | null = null

async function resize(h: number) {
  try { await invoke('set_window_size', { width: W, height: h }) }
  catch {}
}

function onEnter() {
  if (collapseTimer) { clearTimeout(collapseTimer); collapseTimer = null }
  if (!expanded.value) expanded.value = true
}

function onLeave() {
  collapseTimer = setTimeout(() => {
    expanded.value = false
    collapseTimer = null
  }, 80)
}

watch(expanded, (v) => resize(v ? EXPANDED_H : COLLAPSED_H), { immediate: false })
</script>

<template>
  <div class="window">
    <div class="container" :class="{ expanded }" @mouseenter="onEnter" @mouseleave="onLeave">
      <div class="settings-header">
        <SettingsPanel />
      </div>
      <Pill />
      <Transition name="panel">
        <div class="panel-wrap" v-if="expanded">
          <div class="divider"></div>
          <ExpandedPanel />
        </div>
      </Transition>
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
  border-radius: 16px;
  position: absolute;
  top: 0;
  left: 50%;
  transform: translate(-50%, 0);
  width: 100%;
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

.settings-header {
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
