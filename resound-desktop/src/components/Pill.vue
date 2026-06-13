<script setup lang="ts">
import { useNowPlaying } from "../composables/useNowPlaying";
import SettingsPanel from "./SettingsPanel.vue";

const { state } = useNowPlaying();

function artworkUrl(): string {
  if (!state.current.artwork_base64) return "";
  return `data:image/jpeg;base64,${state.current.artwork_base64}`;
}
</script>

<template>
  <div class="pill" data-tauri-drag-region>
    <div class="pill-content">
      <div class="artwork" v-if="state.current.track_title">
        <img v-if="artworkUrl()" :src="artworkUrl()" alt="" />
        <div v-else class="artwork-fallback">♪</div>
      </div>
      <div class="empty-icon" v-else>♪</div>
      <div class="waveform" :class="{ playing: state.current.is_playing }">
        <span v-for="i in 4" :key="i" class="bar"></span>
      </div>
      <div class="gear-wrap">
        <SettingsPanel />
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
}

.pill-content {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 10px;
  width: 100%;
}

.gear-wrap {
  margin-left: auto;
  display: flex;
  align-items: center;
  position: relative;
  z-index: 20;
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

.waveform {
  display: flex;
  align-items: center;
  gap: 2px;
  height: 28px;
}

.bar {
  width: 3px;
  height: 30%;
  background: rgba(255, 255, 255, 0.15);
  border-radius: 2px;
  transition:
    height 0.3s,
    background 0.3s;
}

.playing .bar {
  height: 100%;
  background: rgba(255, 255, 255, 0.4);
}

.playing .bar {
  animation: wave 1s ease-in-out infinite;
}

.playing .bar:nth-child(2) {
  animation-delay: 0.15s;
}
.playing .bar:nth-child(3) {
  animation-delay: 0.3s;
}
.playing .bar:nth-child(4) {
  animation-delay: 0.45s;
}

@keyframes wave {
  0%,
  100% {
    height: 20%;
  }
  50% {
    height: 80%;
  }
}
</style>
