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
    if (this.isHidden(this.treeTarget)) return

    const filter = {
      acceptNode: (node) => {
        if (node.nodeType === Node.ELEMENT_NODE) {
          return this.isHidden(node) ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_SKIP
        }
        return node.nodeValue?.trim() ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT
      }
    }
    const walker = document.createTreeWalker(
      this.treeTarget,
      NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT,
      filter
    )
    let node
    while ((node = walker.nextNode())) {
      this.index.push({ node, text: node.nodeValue.toLowerCase() })
    }
  }

  isHidden(el) {
    return el.classList?.contains('invisible') || el.classList?.contains('d-none') || el.getAttribute('aria-hidden') === 'true'
  }

  // Collects collapsibles to expand for a match: every `.collapse` ancestor in the DOM, plus
  // the collapse target of any `data-bs-toggle="collapse"` ancestor (so matches inside a series
  // header expand the controlled section too).
  collectAncestors(node) {
    const result = []
    for (let el = node.parentElement; el && el !== this.treeTarget; el = el.parentElement) {
      if (el.classList.contains('collapse')) result.push(el)
      if (el.getAttribute('data-bs-toggle') === 'collapse') {
        const id = (el.getAttribute('href') || el.getAttribute('data-bs-target') || '').replace(/^#/, '')
        const target = id && document.getElementById(id)
        if (target?.classList.contains('collapse')) result.push(target)
      }
    }
    return result
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
    for (const { text, node } of this.index) {
      let start = 0, idx
      while ((idx = text.indexOf(query, start)) !== -1) {
        const range = document.createRange()
        range.setStart(node, idx)
        range.setEnd(node, idx + query.length)
        this.matches.push({ range })
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
    const ancestors = this.collectAncestors(match.range.startContainer)
    this.expandAncestors(ancestors, () => {
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
