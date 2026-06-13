<script setup lang="ts">
import { computed } from 'vue'
import { useNowPlaying } from '../composables/useNowPlaying'
import { useVolume } from '../composables/useVolume'
import TransportControls from './TransportControls.vue'
import VolumeSlider from './VolumeSlider.vue'

const { state } = useNowPlaying()
const volume = useVolume()

const elapsedText = computed(() => {
  const t = state.current.progress * state.current.duration
  const m = Math.floor(t / 60)
  const s = Math.floor(t % 60)
  return `${m}:${s.toString().padStart(2, '0')}`
})

const remainingText = computed(() => {
  const t = (1 - state.current.progress) * state.current.duration
  const m = Math.floor(t / 60)
  const s = Math.floor(t % 60)
  return `${m}:${s.toString().padStart(2, '0')}`
})

const progressStyle = computed(() => ({
  width: `${state.current.progress * 100}%`
}))

function artworkUrl(): string {
  if (!state.current.artwork_base64) return ''
  return `data:image/jpeg;base64,${state.current.artwork_base64}`
}
</script>

<template>
  <div class="expanded" v-if="state.current.track_title">
    <div class="top-row">
      <div class="artwork-lg">
        <img v-if="artworkUrl()" :src="artworkUrl()" alt="" />
        <div v-else class="artwork-fallback">♪</div>
      </div>
      <div class="track-info">
        <div class="title">{{ state.current.track_title }}</div>
        <div class="artist">{{ state.current.artist_name }}</div>
      </div>
    </div>

    <div class="progress-row">
      <div class="progress-track">
        <div class="progress-fill" :style="progressStyle"></div>
      </div>
    </div>

    <div class="time-row">
      <span class="time">{{ elapsedText }}</span>
      <span class="time">-{{ remainingText }}</span>
    </div>

    <TransportControls />
    <VolumeSlider :volume="volume.state.level" @set-volume="volume.setVolume" />
  </div>

  <div class="expanded empty" v-else>
    <div class="empty-state">
      <span class="empty-icon">♪</span>
      <span class="empty-text">Nothing is playing</span>
    </div>
  </div>
</template>

<style scoped>
.expanded {
  width: 100%;
}

.top-row {
  display: flex;
  gap: 14px;
  padding: 16px 16px 0;
}

.artwork-lg img {
  width: 52px;
  height: 52px;
  border-radius: 10px;
  object-fit: cover;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

.artwork-fallback {
  width: 52px;
  height: 52px;
  border-radius: 10px;
  background: linear-gradient(135deg, #9c27b0, #009688);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  color: rgba(255, 255, 255, 0.8);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

.track-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 2px;
  min-width: 0;
}

.title {
  font-size: 14px;
  font-weight: 600;
  color: white;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.artist {
  font-size: 11px;
  opacity: 0.45;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.progress-row {
  padding: 10px 16px 0;
}

.progress-track {
  height: 3px;
  background: rgba(255, 255, 255, 0.08);
  border-radius: 2px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 2px;
  will-change: width;
}

.time-row {
  display: flex;
  justify-content: space-between;
  padding: 4px 16px 0;
}

.time {
  font-size: 10px;
  font-weight: 500;
  opacity: 0.4;
  font-variant-numeric: tabular-nums;
}

.empty {
  height: 100px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  opacity: 0.3;
}

.empty-icon {
  font-size: 20px;
}

.empty-text {
  font-size: 12px;
}
</style>
