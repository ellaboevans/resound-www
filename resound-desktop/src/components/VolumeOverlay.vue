<script setup lang="ts">
import { computed } from 'vue'
import { useVolumeOverlay } from '../composables/useVolumeOverlay'

const overlay = useVolumeOverlay()

const iconName = computed(() => {
  if (overlay.state.mode === 'brightness') return '☀'
  if (overlay.state.muted || overlay.state.level === 0) return '🔇'
  if (overlay.state.level < 0.2) return '🔈'
  if (overlay.state.level < 0.5) return '🔉'
  return '🔊'
})

const bars = computed(() => {
  const count = 8
  const fill = Math.round(overlay.state.level * count)
  return Array.from({ length: count }, (_, i) => i < fill)
})

const pct = computed(() => `${Math.round(overlay.state.level * 100)}%`)
</script>

<template>
  <Transition name="fade">
    <div class="overlay" v-if="overlay.state.visible">
      <div class="overlay-inner">
        <span class="icon">{{ iconName }}</span>
        <div class="bars">
          <div
            v-for="(active, i) in bars"
            :key="i"
            class="bar"
            :class="{ active }"
            :style="{ opacity: active ? (i === bars.length - 1 ? 0.5 : 0.7) : 0.1 }"
          ></div>
        </div>
        <span class="pct">{{ pct }}</span>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.overlay {
  position: fixed;
  top: 16px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 9999;
  pointer-events: none;
}

.overlay-inner {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 16px;
  background: #0f0f0f;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 14px;
}

.icon {
  font-size: 13px;
  width: 18px;
  text-align: center;
  opacity: 0.6;
}

.bars {
  display: flex;
  align-items: center;
  gap: 3px;
  height: 22px;
}

.bar {
  width: 6px;
  height: 100%;
  border-radius: 3px;
  background: white;
  transition: opacity 0.1s;
}

.bar.active {
  background: white;
}

.pct {
  font-size: 10px;
  font-weight: 600;
  opacity: 0.4;
  font-variant-numeric: tabular-nums;
  min-width: 30px;
  text-align: right;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
