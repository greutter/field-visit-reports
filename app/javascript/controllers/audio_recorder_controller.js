import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timer", "visualizer", "recordButton", "recordIcon", "status"]
  static values = {
    fieldVisitId: Number,
    uploadUrl: String
  }

  connect() {
    this.isRecording = false
    this.mediaRecorder = null
    this.audioChunks = []
    this.startTime = null
    this.timerInterval = null
    this.audioContext = null
    this.analyser = null
    this.canvasCtx = null
    
    this.setupCanvas()
    this.requestMicrophonePermission()
  }

  disconnect() {
    this.stopRecording()
    if (this.audioContext) {
      this.audioContext.close()
    }
  }

  setupCanvas() {
    const canvas = this.visualizerTarget.querySelector("canvas")
    if (canvas) {
      this.canvasCtx = canvas.getContext("2d")
      canvas.width = canvas.offsetWidth
      canvas.height = canvas.offsetHeight
      this.drawIdleWaveform()
    }
  }

  async requestMicrophonePermission() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      stream.getTracks().forEach(track => track.stop())
      this.statusTarget.textContent = "Tap to start recording"
    } catch (error) {
      console.error("Microphone permission denied:", error)
      this.statusTarget.textContent = "Microphone access denied. Please enable it in your browser settings."
      this.recordButtonTarget.disabled = true
    }
  }

  async toggleRecording() {
    if (this.isRecording) {
      this.stopRecording()
    } else {
      await this.startRecording()
    }
  }

  async startRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ 
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          sampleRate: 44100
        }
      })
      
      this.setupAudioAnalyser(stream)
      
      // Try to use webm if available, otherwise fall back to mp4
      const mimeType = MediaRecorder.isTypeSupported('audio/webm') 
        ? 'audio/webm' 
        : 'audio/mp4'
      
      this.mediaRecorder = new MediaRecorder(stream, { mimeType })
      this.audioChunks = []
      
      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          this.audioChunks.push(event.data)
        }
      }
      
      this.mediaRecorder.onstop = () => {
        this.handleRecordingComplete()
      }
      
      this.mediaRecorder.start(1000) // Collect data every second
      this.isRecording = true
      this.startTime = Date.now()
      this.startTimer()
      this.updateUI()
      this.drawWaveform()
      
    } catch (error) {
      console.error("Error starting recording:", error)
      this.statusTarget.textContent = "Error starting recording. Please try again."
    }
  }

  stopRecording() {
    if (this.mediaRecorder && this.mediaRecorder.state !== "inactive") {
      this.mediaRecorder.stop()
      this.mediaRecorder.stream.getTracks().forEach(track => track.stop())
    }
    
    this.isRecording = false
    this.stopTimer()
    this.updateUI()
    
    if (this.animationId) {
      cancelAnimationFrame(this.animationId)
    }
  }

  setupAudioAnalyser(stream) {
    this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
    this.analyser = this.audioContext.createAnalyser()
    const source = this.audioContext.createMediaStreamSource(stream)
    source.connect(this.analyser)
    this.analyser.fftSize = 256
  }

  drawIdleWaveform() {
    if (!this.canvasCtx) return
    
    const canvas = this.visualizerTarget.querySelector("canvas")
    this.canvasCtx.fillStyle = "rgb(243, 244, 246)"
    this.canvasCtx.fillRect(0, 0, canvas.width, canvas.height)
    
    this.canvasCtx.beginPath()
    this.canvasCtx.moveTo(0, canvas.height / 2)
    this.canvasCtx.lineTo(canvas.width, canvas.height / 2)
    this.canvasCtx.strokeStyle = "rgb(209, 213, 219)"
    this.canvasCtx.stroke()
  }

  drawWaveform() {
    if (!this.isRecording || !this.analyser || !this.canvasCtx) {
      this.drawIdleWaveform()
      return
    }
    
    this.animationId = requestAnimationFrame(() => this.drawWaveform())
    
    const canvas = this.visualizerTarget.querySelector("canvas")
    const bufferLength = this.analyser.frequencyBinCount
    const dataArray = new Uint8Array(bufferLength)
    this.analyser.getByteTimeDomainData(dataArray)
    
    this.canvasCtx.fillStyle = "rgb(254, 242, 242)"
    this.canvasCtx.fillRect(0, 0, canvas.width, canvas.height)
    
    this.canvasCtx.lineWidth = 2
    this.canvasCtx.strokeStyle = "rgb(239, 68, 68)"
    this.canvasCtx.beginPath()
    
    const sliceWidth = canvas.width / bufferLength
    let x = 0
    
    for (let i = 0; i < bufferLength; i++) {
      const v = dataArray[i] / 128.0
      const y = (v * canvas.height) / 2
      
      if (i === 0) {
        this.canvasCtx.moveTo(x, y)
      } else {
        this.canvasCtx.lineTo(x, y)
      }
      
      x += sliceWidth
    }
    
    this.canvasCtx.lineTo(canvas.width, canvas.height / 2)
    this.canvasCtx.stroke()
  }

  startTimer() {
    this.timerInterval = setInterval(() => {
      const elapsed = Math.floor((Date.now() - this.startTime) / 1000)
      const minutes = Math.floor(elapsed / 60).toString().padStart(2, "0")
      const seconds = (elapsed % 60).toString().padStart(2, "0")
      this.timerTarget.textContent = `${minutes}:${seconds}`
    }, 1000)
  }

  stopTimer() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
      this.timerInterval = null
    }
  }

  updateUI() {
    if (this.isRecording) {
      this.recordButtonTarget.classList.remove("bg-red-500", "hover:bg-red-600")
      this.recordButtonTarget.classList.add("bg-red-600", "animate-pulse")
      this.recordIconTarget.innerHTML = '<rect x="6" y="6" width="12" height="12" rx="1"/>'
      this.statusTarget.textContent = "Recording... Tap to stop"
    } else {
      this.recordButtonTarget.classList.add("bg-red-500", "hover:bg-red-600")
      this.recordButtonTarget.classList.remove("bg-red-600", "animate-pulse")
      this.recordIconTarget.innerHTML = '<circle cx="12" cy="12" r="6"/>'
      this.statusTarget.textContent = "Tap to start recording"
    }
  }

  async handleRecordingComplete() {
    const duration = Math.floor((Date.now() - this.startTime) / 1000)
    
    const mimeType = this.mediaRecorder.mimeType
    const blob = new Blob(this.audioChunks, { type: mimeType })
    
    // Determine file extension
    const extension = mimeType.includes('webm') ? 'webm' : 'm4a'
    
    this.statusTarget.textContent = "Uploading..."
    
    try {
      await this.uploadAudio(blob, duration, extension)
      this.timerTarget.textContent = "00:00"
      this.statusTarget.textContent = "Upload complete! Tap to record again"
      this.drawIdleWaveform()
      
      // Reload to show the new audio message
      window.location.reload()
    } catch (error) {
      console.error("Upload failed:", error)
      this.statusTarget.textContent = "Upload failed. Please try again."
    }
  }

  async uploadAudio(blob, duration, extension) {
    const formData = new FormData()
    formData.append("audio_message[audio_file]", blob, `recording_${Date.now()}.${extension}`)
    formData.append("audio_message[duration_seconds]", duration)
    
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    
    const response = await fetch(this.uploadUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      },
      body: formData
    })
    
    if (!response.ok) {
      throw new Error(`Upload failed: ${response.status}`)
    }
    
    return response.json()
  }
}
