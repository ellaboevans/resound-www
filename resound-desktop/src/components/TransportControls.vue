<script setup lang="ts">
import { useNowPlaying } from '../composables/useNowPlaying'

const { state, playPause, nextTrack, prevTrack } = useNowPlaying()
</script>

<template>
  <div class="transport">
    <button class="ctrl-btn" @click="prevTrack">
      <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
        <polygon points="10,2 10,14 3,8" />
        <polygon points="14,2 14,14 7,8" />
      </svg>
    </button>
    <button class="play-btn" @click="playPause">
      <svg v-if="state.current.is_playing" width="14" height="14" viewBox="0 0 14 14" fill="currentColor">
        <rect x="1" y="0" width="4" height="14" rx="1" />
        <rect x="9" y="0" width="4" height="14" rx="1" />
      </svg>
      <svg v-else width="14" height="14" viewBox="0 0 14 14" fill="currentColor">
        <polygon points="0,0 14,7 0,14" />
      </svg>
    </button>
    <button class="ctrl-btn" @click="nextTrack">
      <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
        <polygon points="6,2 6,14 13,8" />
        <polygon points="2,2 2,14 9,8" />
      </svg>
    </button>
  </div>
</template>

<style scoped>
.transport {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 28px;
  padding: 8px 16px;
}

.ctrl-btn {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.45);
  font-size: 16px;
  cursor: pointer;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.12s ease, opacity 0.12s ease;
}

.ctrl-btn:active {
  transform: scale(0.92);
  opacity: 0.7;
}

.play-btn {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: white;
  border: none;
  color: black;
  font-size: 14px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.12s ease;
}

.play-btn:active {
  transform: scale(0.92);
}
</style>
