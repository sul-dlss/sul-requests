import { Controller } from "@hotwired/stimulus"

// Polls the confirmation page turbo frame until all expected Aeon requests
// have appeared, or max attempts are reached.
export default class extends Controller {
  static values = {
    expectedCount: Number,
    interval: { type: Number, default: 1000 },
    maxAttempts: { type: Number, default: 10 }
  }

  static targets = ["frame", "loading"]

  connect() {
    this.attempts = 0

    if (this.complete()) {
      this.hideLoading()
      return
    }

    this.frameTarget.addEventListener("turbo:frame-load", this.onFrameLoad)
    this.scheduleNext()
  }

  disconnect() {
    clearTimeout(this.timer)

    if (this.hasFrameTarget) {
      this.frameTarget.removeEventListener("turbo:frame-load", this.onFrameLoad)
    }
  }

  scheduleNext() {
    this.timer = setTimeout(() => this.refresh(), this.intervalValue)
  }

  refresh() {
    this.attempts++

    if (this.attempts >= this.maxAttemptsValue) {
      this.hideLoading()
      return
    }

    const url = new URL(window.location.href)
    url.searchParams.set("_poll", Date.now())
    this.frameTarget.src = url.toString()
  }

  onFrameLoad = () => {
    if (this.complete()) {
      this.hideLoading()
    } else {
      this.scheduleNext()
    }
  }

  complete() {
    return this.currentCount() >= this.expectedCountValue
  }

  currentCount() {
    return this.frameTarget.querySelectorAll("[data-aeon-request]").length
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.hidden = true
    }
  }
}
