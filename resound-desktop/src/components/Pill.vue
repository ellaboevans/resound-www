<script setup lang="ts">
import { ref } from 'vue'
import { useNowPlaying } from '../composables/useNowPlaying'

const { state } = useNowPlaying()
const isHovering = ref(false)

const emit = defineEmits<{
  (e: 'expand', v: boolean): void
}>()

function onHover(v: boolean) {
  isHovering.value = v
  emit('expand', v)
}

function artworkUrl(): string {
  if (!state.current.artwork_base64) return ''
  return `data:image/jpeg;base64,${state.current.artwork_base64}`
}
</script>

<template>
  <div
    class="pill"
    @mouseenter="onHover(true)"
    @mouseleave="onHover(false)"
    :class="{ hovering: isHovering }"
  >
    <div class="pill-content">
      <div class="artwork" v-if="state.current.track_title">
        <img v-if="artworkUrl()" :src="artworkUrl()" alt="" />
        <div v-else class="artwork-fallback">
          <span>♪</span>
        </div>
      </div>
      <div class="empty-icon" v-else>
        <span>♪</span>
      </div>
      <div class="waveform">
        <span v-for="i in 4" :key="i" class="bar" :style="{ animationDelay: `${i * 0.15}s` }"></span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.pill {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  transition: transform 0.15s ease;
}

.pill.hovering {
  transform: scale(1.03);
}

.pill-content {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 10px;
}

.artwork img {
  width: 22px;
  height: 22px;
  border-radius: 6px;
  object-fit: cover;
}

.artwork-fallback,
.empty-icon {
  width: 22px;
  height: 22px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  color: rgba(255, 255, 255, 0.5);
}

.artwork-fallback {
  background: linear-gradient(135deg, #e91e63, #f44336);
}

.empty-icon span {
  color: #888;
  font-size: 11px;
}

.waveform {
  display: flex;
  align-items: center;
  gap: 2px;
  height: 28px;
}

.bar {
  width: 3px;
  height: 100%;
  background: rgba(255, 255, 255, 0.4);
  border-radius: 2px;
  animation: wave 1s ease-in-out infinite;
}

@keyframes wave {
  0%, 100% { height: 20%; }
  50% { height: 80%; }
}
</style>
