<script lang="ts" setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { StartTimer, PauseTimer, StopTimer, GetTimerStatus } from '../wailsjs/go/main/App'

// Timer state
const timerStatus = ref({
  state: 'idle',
  remainingTime: 0,
  currentCycle: 1,
  completedPomodoros: 0
})

const isRunning = ref(false)
const isPaused = ref(false)
let statusInterval: number

// Format time for display
const formatTime = (seconds: number): string => {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
}

// Get state display text
const getStateText = (state: string): string => {
  switch (state) {
    case 'working': return 'Focus Time'
    case 'break': return 'Short Break'
    case 'longBreak': return 'Long Break'
    case 'paused': return 'Paused'
    default: return 'Ready to Focus'
  }
}

// Get state color
const getStateColor = (state: string): string => {
  switch (state) {
    case 'working': return '#e74c3c'
    case 'break': return '#27ae60'
    case 'longBreak': return '#3498db'
    case 'paused': return '#f39c12'
    default: return '#95a5a6'
  }
}

// Timer controls
const startTimer = async () => {
  try {
    const status = await StartTimer()
    timerStatus.value = status
    isRunning.value = true
    isPaused.value = false
  } catch (error) {
    console.error('Failed to start timer:', error)
  }
}

const pauseTimer = async () => {
  try {
    const status = await PauseTimer()
    timerStatus.value = status
    isRunning.value = false
    isPaused.value = true
  } catch (error) {
    console.error('Failed to pause timer:', error)
  }
}

const stopTimer = async () => {
  try {
    const status = await StopTimer()
    timerStatus.value = status
    isRunning.value = false
    isPaused.value = false
  } catch (error) {
    console.error('Failed to stop timer:', error)
  }
}

// Update timer status periodically
const updateStatus = async () => {
  try {
    const status = await GetTimerStatus()
    timerStatus.value = status
    isRunning.value = status.state === 'working' || status.state === 'break' || status.state === 'longBreak'
    isPaused.value = status.state === 'paused'
  } catch (error) {
    console.error('Failed to get timer status:', error)
  }
}

onMounted(() => {
  updateStatus()
  statusInterval = setInterval(updateStatus, 1000)
})

onUnmounted(() => {
  if (statusInterval) {
    clearInterval(statusInterval)
  }
})
</script>

<template>
  <div class="pomodoro-app">
    <div class="timer-container">
      <!-- Timer Display -->
      <div class="timer-display" :style="{ borderColor: getStateColor(timerStatus.state) }">
        <div class="state-text" :style="{ color: getStateColor(timerStatus.state) }">
          {{ getStateText(timerStatus.state) }}
        </div>
        <div class="time-text">
          {{ formatTime(timerStatus.remainingTime) }}
        </div>
        <div class="cycle-info">
          Cycle {{ timerStatus.currentCycle }} • {{ timerStatus.completedPomodoros }} completed
        </div>
      </div>

      <!-- Controls -->
      <div class="controls">
        <button 
          v-if="!isRunning && !isPaused" 
          @click="startTimer"
          class="btn btn-start"
        >
          🍅 Start Focus
        </button>
        
        <button 
          v-if="isPaused" 
          @click="startTimer"
          class="btn btn-resume"
        >
          ▶️ Resume
        </button>
        
        <button 
          v-if="isRunning" 
          @click="pauseTimer"
          class="btn btn-pause"
        >
          ⏸️ Pause
        </button>
        
        <button 
          v-if="isRunning || isPaused" 
          @click="stopTimer"
          class="btn btn-stop"
        >
          ⏹️ Stop
        </button>
      </div>

      <!-- Progress Indicator -->
      <div class="progress-container">
        <div class="progress-dots">
          <div 
            v-for="i in 4" 
            :key="i"
            class="progress-dot"
            :class="{ 
              'completed': i <= timerStatus.completedPomodoros % 4,
              'current': i === (timerStatus.completedPomodoros % 4) + 1 && isRunning
            }"
          ></div>
        </div>
        <div class="progress-text">
          Next long break in {{ 4 - (timerStatus.completedPomodoros % 4) }} pomodoros
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.pomodoro-app {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

.timer-container {
  text-align: center;
  background: rgba(255, 255, 255, 0.95);
  padding: 3rem;
  border-radius: 2rem;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.1);
  backdrop-filter: blur(10px);
  max-width: 400px;
  width: 90vw;
}

.timer-display {
  margin-bottom: 2rem;
  padding: 2rem;
  border: 4px solid #95a5a6;
  border-radius: 50%;
  width: 250px;
  height: 250px;
  margin: 0 auto 2rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  transition: border-color 0.3s ease;
}

.state-text {
  font-size: 1.2rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.time-text {
  font-size: 3rem;
  font-weight: 700;
  color: #2c3e50;
  font-family: 'Courier New', monospace;
}

.cycle-info {
  font-size: 0.9rem;
  color: #7f8c8d;
  margin-top: 0.5rem;
}

.controls {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-bottom: 2rem;
  flex-wrap: wrap;
}

.btn {
  padding: 0.8rem 1.5rem;
  border: none;
  border-radius: 2rem;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  min-width: 120px;
}

.btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.15);
}

.btn-start {
  background: linear-gradient(45deg, #e74c3c, #c0392b);
  color: white;
}

.btn-resume {
  background: linear-gradient(45deg, #27ae60, #229954);
  color: white;
}

.btn-pause {
  background: linear-gradient(45deg, #f39c12, #d68910);
  color: white;
}

.btn-stop {
  background: linear-gradient(45deg, #95a5a6, #7f8c8d);
  color: white;
}

.progress-container {
  margin-top: 1rem;
}

.progress-dots {
  display: flex;
  justify-content: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.progress-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #ecf0f1;
  transition: all 0.3s ease;
}

.progress-dot.completed {
  background: #e74c3c;
  transform: scale(1.2);
}

.progress-dot.current {
  background: #f39c12;
  transform: scale(1.3);
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

.progress-text {
  font-size: 0.8rem;
  color: #7f8c8d;
}
</style>