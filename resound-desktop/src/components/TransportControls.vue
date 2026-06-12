<script setup lang="ts">
import { useNowPlaying } from '../composables/useNowPlaying'

const { state, playPause, nextTrack, prevTrack } = useNowPlaying()
</script>

<template>
  <div class="transport">
    <button class="ctrl-btn" @click="prevTrack">⏮</button>
    <button class="play-btn" @click="playPause">
      {{ state.current.is_playing ? '⏸' : '▶' }}
    </button>
    <button class="ctrl-btn" @click="nextTrack">⏭</button>
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
