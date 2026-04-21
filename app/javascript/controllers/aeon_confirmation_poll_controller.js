import { Controller } from "@hotwired/stimulus"

// Polls the confirmation page turbo frame until all expected Aeon requests
// have appeared, or max attempts are reached.
export default class extends Controller {
  static values = {
    attempts: Number,
    interval: { type: Number, default: 1000 },
    maxAttempts: { type: Number, default: 20 }
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

    if (this.attemptsValue >= this.maxAttemptsValue) return

    const url = new URL(window.location.href)
    url.searchParams.set("_poll", Date.now())
    this.frameTarget.src = url.toString()
  }
}
