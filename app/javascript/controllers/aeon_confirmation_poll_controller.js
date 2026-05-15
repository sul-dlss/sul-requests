import { Controller } from "@hotwired/stimulus"

// Polls the confirmation page turbo frame until all expected Aeon requests
// have appeared, or max attempts are reached.
export default class extends Controller {
  static values = {
    attempts: Number,
    interval: { type: Number, default: 1000 },
    maxAttempts: { type: Number, default: 10 }
  }

  static targets = ["frame", "loading"]

  loadingTargetConnected() {
    this.scheduleNext()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  scheduleNext() {
    this.timer = setTimeout(() => this.refresh(), this.intervalValue)
  }

  refresh() {
    this.attemptsValue++

    const url = new URL(window.location.href)
    url.searchParams.set("_poll", Date.now())
    if (this.attemptsValue >= this.maxAttemptsValue) {
      url.searchParams.set("stop_polling", "1")
    }
    this.frameTarget.src = url.toString()
  }
}
