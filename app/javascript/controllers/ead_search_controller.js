import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ["input", "tree", "countPill", "countText", "prevButton", "nextButton", "clearButton"]
  static values = {
    currentMatchName: { type: String, default: 'ead-current-match' },
    debounce: { type: Number, default: 200 },
    matchName: { type: String, default: 'ead-match' },
    minQueryLength: { type: Number, default: 3 },
    transitionClass: { type: String, default: 'ead-search-no-transition' }
  }

  connect() {
    this.index = []
    this.debounceHandle = null
    this.buildIndex()
    this.resetMatches()
    this.highlightsSupported = typeof CSS !== 'undefined' && CSS.highlights
    if (this.highlightsSupported) {
      this.matchHighlight = new Highlight()
      this.currentMatchHighlight = new Highlight()
      CSS.highlights.set(this.matchNameValue, this.matchHighlight)
      CSS.highlights.set(this.currentMatchNameValue, this.currentMatchHighlight)
    }
  }

  disconnect() {
    this.clearHighlights()
    if (this.debounceHandle) clearTimeout(this.debounceHandle)
  }

  buildIndex() {
    if (!this.hasTreeTarget) return
    const walk = (el, ancestors) => {
      if (el.classList?.contains('invisible') || el.classList?.contains('d-none') || el.getAttribute('aria-hidden') === 'true') return

      let nextAncestors = el !== this.treeTarget && el.classList?.contains('collapse') ? ancestors.concat(el) : ancestors

      // For matches that land on collapsables like series headers, assume the user wants to see the contexts and expand.
      if (el.getAttribute?.('data-bs-toggle') === 'collapse') {
        const targetId = (el.getAttribute('href') || el.getAttribute('data-bs-target') || '').replace(/^#/, '')
        const target = targetId && document.getElementById(targetId)
        if (target?.classList.contains('collapse')) nextAncestors = nextAncestors.concat(target)
      }

      for (let child = el.firstChild; child; child = child.nextSibling) {
        if (child.nodeType === Node.TEXT_NODE) {
          const value = child.nodeValue
          if (value?.trim()) this.index.push({ node: child, text: value.toLowerCase(), ancestors: nextAncestors })
        } else if (child.nodeType === Node.ELEMENT_NODE) {
          walk(child, nextAncestors)
        }
      }
    }
    walk(this.treeTarget, [])
  }

  onInput() {
    clearTimeout(this.debounceHandle)
    this.debounceHandle = setTimeout(() => this.search(), this.debounceValue)
  }

  clear() {
    if (this.hasInputTarget) this.inputTarget.value = ''
    this.resetMatches()
  }

  resetMatches() {
    this.matches = []
    this.currentIndex = -1
    this.clearHighlights()
    this.renderPill()
  }

  search() {
    const query = this.inputTarget.value.toLowerCase()
    if (query.length < this.minQueryLengthValue) return this.resetMatches()

    this.matches = []
    for (const { text, node, ancestors } of this.index) {
      let start = 0, idx
      while ((idx = text.indexOf(query, start)) !== -1) {
        const range = document.createRange()
        range.setStart(node, idx)
        range.setEnd(node, idx + query.length)
        this.matches.push({ range, ancestors })
        start = idx + query.length
      }
    }
    this.currentIndex = this.matches.length ? 0 : -1
    this.paintHighlights()
    this.renderPill()
    if (this.currentIndex >= 0) this.revealCurrent()
  }

  paintHighlights() {
    if (!this.highlightsSupported) return

    this.clearHighlights()
    if (!this.matches.length) return
    for (const { range } of this.matches) this.matchHighlight.add(range)
    if (this.currentIndex >= 0) this.currentMatchHighlight.add(this.matches[this.currentIndex].range)
  }

  clearHighlights() {
    if (!this.highlightsSupported) return

    this.matchHighlight.clear()
    this.currentMatchHighlight.clear()
  }

  revealCurrent() {
    const match = this.matches[this.currentIndex]
    if (!match) return
    this.expandAncestors(match.ancestors, () => {
      this.paintHighlights()
      match.range.startContainer.parentElement?.scrollIntoView({ block: 'center', behavior: 'auto' })
    })
  }

  expandAncestors(ancestors, done) {
    if (!ancestors.length) return done?.()

    this.treeTarget.classList.add(this.transitionClassValue)

    const needsExpand = ancestors.filter(el => !el.classList.contains('show'))

    if (!needsExpand.length) {
      this.treeTarget.classList.remove(this.transitionClassValue)
      return done?.()
    }

    let pending = needsExpand.length
    const onShown = () => {
      if (--pending === 0) {
        this.treeTarget.classList.remove(this.transitionClassValue)
        done?.()
      }
    }

    for (const el of needsExpand) {
      el.addEventListener('shown.bs.collapse', onShown, { once: true })
      Collapse.getOrCreateInstance(el, { toggle: false }).show()
    }
  }

  next(event) { this.step(event, 1) }
  prev(event) { this.step(event, -1) }

  step(event, dir) {
    event?.preventDefault()
    if (!this.matches.length) return
    this.currentIndex = (this.currentIndex + dir + this.matches.length) % this.matches.length
    this.paintHighlights()
    this.renderPill()
    this.revealCurrent()
  }

  onKeydown(event) {
    if (event.key === 'Enter') { event.preventDefault(); event.shiftKey ? this.prev() : this.next() }
    else if (event.key === 'Escape') this.clear()
  }

  renderPill() {
    if (!this.hasCountPillTarget) return

    const active = (this.hasInputTarget ? this.inputTarget.value : '').length >= this.minQueryLengthValue
    this.countPillTarget.classList.toggle('d-none', !active)
    this.countPillTarget.classList.toggle('d-flex', active)
    if (!active) return

    if (this.hasCountTextTarget) {
      this.countTextTarget.textContent = this.matches.length ? `${this.currentIndex + 1} of ${this.matches.length} matches` : '0 matches'
    }
    const disabled = !this.matches.length
    if (this.hasPrevButtonTarget) this.prevButtonTarget.disabled = disabled
    if (this.hasNextButtonTarget) this.nextButtonTarget.disabled = disabled
  }
}
