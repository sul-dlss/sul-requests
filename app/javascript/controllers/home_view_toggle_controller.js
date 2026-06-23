import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { storageKey: { type: String, default: "sulRequests:homeView" } }

  connect() {
    const stored = window.localStorage.getItem(this.storageKeyValue)
    if (stored === "card" || stored === "list") {
      this.element.dataset.homeView = stored
    }
    this.syncButtons()
  }

  set(event) {
    const variant = event.params.variant
    if (variant !== "card" && variant !== "list") return
    this.element.dataset.homeView = variant
    window.localStorage.setItem(this.storageKeyValue, variant)
    this.syncButtons()
  }

  syncButtons() {
    const current = this.element.dataset.homeView
    this.element.querySelectorAll("[data-home-view-toggle-variant-param]").forEach((btn) => {
      const isActive = btn.dataset.homeViewToggleVariantParam === current
      btn.classList.toggle("active", isActive)
      btn.setAttribute("aria-pressed", isActive ? "true" : "false")
    })
  }
}
