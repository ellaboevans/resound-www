<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  volume: number
}>()

const emit = defineEmits<{
  (e: 'setVolume', v: number): void
}>()

const iconName = computed(() => {
  if (props.volume === 0) return '🔇'
  if (props.volume < 30) return '🔈'
  if (props.volume < 70) return '🔉'
  return '🔊'
})

function onInput(e: Event) {
  const target = e.target as HTMLInputElement
  emit('setVolume', parseInt(target.value))
}
</script>

<template>
  <div class="volume-slider">
    <span class="icon">{{ iconName }}</span>
    <input
      type="range"
      min="0"
      max="100"
      :value="volume"
      @input="onInput"
      class="slider"
    />
    <span class="label">{{ volume }}%</span>
  </div>
</template>

<style scoped>
.volume-slider {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px 16px;
}

.icon {
  font-size: 11px;
  width: 16px;
  text-align: center;
  opacity: 0.6;
}

.slider {
  flex: 1;
  -webkit-appearance: none;
  appearance: none;
  height: 3px;
  border-radius: 2px;
  background: rgba(255, 255, 255, 0.15);
  outline: none;
}

.slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: white;
  cursor: pointer;
}

.label {
  font-size: 10px;
  font-weight: 600;
  opacity: 0.4;
  min-width: 28px;
  text-align: right;
  font-variant-numeric: tabular-nums;
}
</style>
