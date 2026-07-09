import { Controller } from "@hotwired/stimulus"

// Custom date picker.
//
// Data attributes on the controller element:
//   data-date-picker-disabled-value         JSON array of ISO dates to disable, e.g. '["2026-04-24","2026-04-27"]'
//   data-date-picker-open-days-value        JSON array of daynames to enable, e.g. '["Monday", "Tuesday"]'
//   data-date-picker-min-value              ISO date string; any date before this is disabled, e.g. '"2026-04-23"'
//   data-date-picker-max-value              ISO date string; any date after this is disabled, e.g. '"2027-03-01"'
//   data-date-picker-marked-value           JSON array of ISO dates to mark with a dot, e.g. '["2026-04-23"]'
//   data-date-picker-availability-url-value Optional URL probed per visible month for { unavailable_dates }
//
// Targets:
//   input              hidden <input> that holds the selected ISO date value
//   button             clickable element (button/span) that shows the formatted date and opens/closes the calendar
//   selectedValue      the selected value as displayed in the button
//   calendar           the popup wrapper div
//   monthLabel         element where the current month/year label is rendered
//   grid               element where the day buttons are rendered
//   availabilityStatus optional element shown while a month's availability is being fetched
export default class extends Controller {
  static targets = ["input", "calendar", "button", "selectedValue", "monthLabel", "grid", "announce", "prevBtn", "nextBtn", "legend", "availabilityStatus", "leadTimeMessage"]
  static values = {
    disabled: Array, marked: Array, min: String, max: String, openDays: Array, year: Number, month: Number, focused: String,
    availabilityUrl: String,
    today: {
      type: String,
      default: new Date().toISOString().slice(0, 10) // "YYYY-MM-DD"
    }
   }

  connect() {
    this.monthStatus = new Map() // key -> "pending" | "done"

    // set the initially focused value to the selected day, or the first available day
    this.focusedValue = this.inputTarget.value || this.#toIsoDate(this.nextEnabledDateOnOrAfter(new Date(this.todayValue), 1));
    this.element.addEventListener("keydown", this.#handleKeydown)
  }

  openDaysValueChanged() {
    let dayToIntMapping = { Sunday: 0, Monday: 1, Tuesday: 2, Wednesday: 3, Thursday: 4, Friday: 5, Saturday: 6}

    this.openDayInts = this.openDaysValue.map(name => dayToIntMapping[name])
  }

  disconnect() {
    document.removeEventListener("click", this.#handleOutsideClick)
    this.element.removeEventListener("keydown", this.#handleKeydown)
  }

  toggle() {
    this.calendarTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.renderCalendar()
    this.calendarTarget.hidden = false
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.announceTarget.textContent = `Date picker, ${this.monthLabelTarget.textContent}. Use arrow keys to navigate dates, Tab to move between controls, Escape to close.`
    requestAnimationFrame(() => {
      this.gridTarget.querySelector("button[tabindex='0']")?.focus({ focusVisible: true })
    })

    document.addEventListener("click", this.#handleOutsideClick)
  }

  close() {
    this.calendarTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.buttonTarget.focus()

    document.removeEventListener("click", this.#handleOutsideClick)
  }

  prevMonth() {
    if (this.monthValue === 0) { this.monthValue = 11; this.yearValue-- }
    else { this.monthValue-- }
    this.renderCalendar()
    this.announceTarget.textContent = this.monthLabelTarget.textContent
  }

  nextMonth() {
    if (this.monthValue === 11) { this.monthValue = 0; this.yearValue++ }
    else { this.monthValue++ }
    this.renderCalendar()
    this.announceTarget.textContent = this.monthLabelTarget.textContent
  }

  selectDay(event) {
    const date = event.params.date
    this.inputTarget.value = date
    this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))
    const formatted = this.#formatDisplay(date)
    this.selectedValueTarget.textContent = formatted
    this.announceTarget.textContent = `Selected ${formatted}`
    this.focusedValue = date
    this.close()
  }

  renderCalendar() {
    const { yearValue: year, monthValue: month } = this
    const monthLabelText = new Date(year, month, 1)
      .toLocaleDateString("en-US", { month: "long", year: "numeric" })
    this.monthLabelTarget.textContent = monthLabelText

    const firstDayOfWeek = new Date(year, month, 1).getDay() // 0 = Sunday
    const daysInMonth = new Date(year, month + 1, 0).getDate()
    const selected = this.inputTarget.value

    const dayNames = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    const rows = [["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]]
    let week = Array(firstDayOfWeek).fill(null)

    for (let day = 1; day <= daysInMonth; day++) {
      week.push(day)
      if (week.length === 7) { rows.push(week); week = [] }
    }
    if (week.length) rows.push(week.concat(Array(7 - week.length).fill(null)))

    // Build DOM nodes — no innerHTML interpolation of user data
    const table = document.createElement("table")
    table.className = "date-picker-grid w-100 text-center"
    table.setAttribute("role", "grid")
    table.setAttribute("aria-label", `${monthLabelText} calendar`)

    const thead = table.createTHead()
    const headerRow = thead.insertRow()
    dayNames.forEach(name => {
      const th = document.createElement("th")
      th.className = "date-picker-day-name small text-muted pb-1"
      th.scope = "col"
      th.textContent = name
      headerRow.appendChild(th)
    })

    const tbody = table.createTBody()
    rows.slice(1).forEach(weekDays => {
      const tr = tbody.insertRow()
      weekDays.forEach((day, index) => {
        const td = tr.insertCell()
        if (day === null) return
        const isoDate = [
          year,
          String(month + 1).padStart(2, "0"),
          String(day).padStart(2, "0")
        ].join("-")

        const isMarked = this.markedValue.includes(isoDate)
        const isSelected = isoDate === selected

        td.setAttribute("role", "gridcell")

        const btn = document.createElement("button")
        btn.type = "button"
        btn.className = [
          "date-picker-day",
          "btn btn-sm w-100 position-relative",
          isSelected ? "btn-primary" : "btn-light"
        ].join(" ")
        btn.dataset.datePickerDateParam = isoDate
        btn.dataset.action = "date-picker#selectDay"
        btn.disabled = this.#isDateDisabled(isoDate, index)
        btn.setAttribute("aria-pressed", String(isSelected))
        btn.tabIndex = isoDate === this.focusedValue ? 0 : -1
        btn.textContent = day

        // Build accessible label: "April 22, 2026" + optional ", existing appointment"
        const [y, mo, d] = isoDate.split("-").map(Number)
        let label = new Date(y, mo - 1, d).toLocaleDateString("en-US", {
          month: "long", day: "numeric", year: "numeric"
        })
        if (isMarked) label += ", existing appointment"
        btn.setAttribute("aria-label", label)

        if (isMarked) {
          const dot = document.createElement("span")
          dot.className = "date-picker-dot"
          dot.setAttribute("aria-hidden", "true")
          btn.appendChild(dot)
        }

        td.appendChild(btn)
      })
    })

    this.gridTarget.replaceChildren(table)

    // Show legend only when at least one marked day falls in this month
    if (this.hasLegendTarget) {
      const prefix = `${year}-${String(month + 1).padStart(2, "0")}-`
      const anyMarked = this.markedValue.some(d => d.startsWith(prefix))
      this.legendTarget.style.visibility = anyMarked ? "visible" : "hidden"
    }

    // Fallback: if focusedValue is outside this month or disabled, use the first enabled day
    let focusedBtn = this.gridTarget.querySelector("button[tabindex='0']")
    if (!focusedBtn || focusedBtn.disabled) {
      focusedBtn = this.gridTarget.querySelector("button:not(:disabled)")
      if (focusedBtn) {
        focusedBtn.tabIndex = 0
        this.focusedValue = focusedBtn.dataset.datePickerDateParam
      }
    }

    this.#isPrevNextDisabled()
    this.#fetchMonthAvailability(year, month)
    this.#fetchMonthAvailability(...this.#nextMonth(year, month))
    this.#updateAvailabilityStatus()
  }

  // --- private ---

  #nextMonth(year, month) {
    return month === 11 ? [year + 1, 0] : [year, month + 1]
  }

  async #fetchMonthAvailability(year, month) {
    const key = `${year}-${String(month + 1).padStart(2, "0")}`
    if (!this.availabilityUrlValue || this.monthStatus.has(key)) return
    this.monthStatus.set(key, "pending")
    this.#updateAvailabilityStatus()

    try {
      const additions = await this.#requestUnavailableDates(key)
      if (additions.length > 0) {
        this.disabledValue = [...new Set([...this.disabledValue, ...additions])]
        this.renderCalendar()
      }
      this.monthStatus.set(key, "done")
    } catch (e) {
      this.monthStatus.delete(key)
      throw e
    } finally {
      this.#updateAvailabilityStatus()
    }
  }

  async #requestUnavailableDates(monthKey) {
    const sep = this.availabilityUrlValue.includes("?") ? "&" : "?"
    const url = `${this.availabilityUrlValue}${sep}month=${monthKey}`
    const res = await fetch(url, { headers: { Accept: "application/json" } })
    if (!res.ok) throw new Error(`HTTP ${res.status} fetching ${url}`)
    const data = await res.json()
    return data.unavailable_dates || []
  }

  #updateAvailabilityStatus() {
    if (!this.hasAvailabilityStatusTarget) return
    const visibleKey = `${this.yearValue}-${String(this.monthValue + 1).padStart(2, "0")}`
    this.availabilityStatusTarget.hidden = this.monthStatus.get(visibleKey) !== "pending"
  }

  #formatDisplay(isoDate) {
    const [y, m, d] = isoDate.split("-").map(Number)
    return new Date(y, m - 1, d).toLocaleDateString("en-US", {
      month: "long", day: "numeric", year: "numeric"
    })
  }

  #toIsoDate(date) {
    if (!date) return;

    return [
      date.getFullYear(),
      String(date.getMonth() + 1).padStart(2, "0"),
      String(date.getDate()).padStart(2, "0")
    ].join("-")
  }

  #isPrevNextDisabled() {
    this.prevBtnTarget.disabled =  new Date(this.yearValue, this.monthValue, 1) <= new Date()
    const nextDisabled = new Date(this.yearValue, this.monthValue + 1, 1) > new Date(this.maxValue)
    this.nextBtnTarget.disabled = nextDisabled
    if (this.hasLeadTimeMessageTarget) this.leadTimeMessageTarget.hidden = !nextDisabled
  }

  #isDateDisabled(isoDate, index) {
    return this.disabledValue.includes(isoDate) ||
      (this.minValue && isoDate < this.minValue) || (this.maxValue && isoDate > this.maxValue) || !this.openDayInts.includes(index)
  }

  #handleOutsideClick = (event) => {
    if (!this.element.contains(event.target)) this.close()
  }

  #handleKeydown = (event) => {
    if (this.calendarTarget.hidden) return

    if (event.key === "Escape") {
      event.stopPropagation()
      this.close()
      return
    }

    // Focus trap: Tab cycles through prevBtn → nextBtn → focused day → prevBtn
    if (event.key === "Tab") {
      const focusedDay = this.gridTarget.querySelector("button[tabindex='0']")
      if (!event.shiftKey && document.activeElement === focusedDay) {
        event.preventDefault()
        const focusButton = this.prevBtnTarget.disabled ? this.nextBtnTarget : this.prevBtnTarget
        focusButton.focus({ focusVisible: true })
      } else if (event.shiftKey && document.activeElement === this.prevBtnTarget) {
        event.preventDefault()
        focusedDay?.focus({ focusVisible: true })
      }
      return
    }

    // Arrow key navigation within the grid
    if (!this.gridTarget.contains(document.activeElement)) return

    const delta = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -7, ArrowDown: 7 }[event.key]
    if (delta === undefined) return

    event.preventDefault()

    const step = delta > 0 ? 1 : -1
    let candidate = new Date(this.focusedValue + "T00:00:00")
    candidate.setDate(candidate.getDate() + delta)

    const nextDate = this.nextEnabledDateOnOrAfter(candidate, step)

    if (nextDate) this.focusedValue = this.#toIsoDate(nextDate);
  }

  nextEnabledDateOnOrAfter(candidate, step, maximumDatesToExamine = 365) {
    // Skip over disabled dates (guard against all dates being disabled)
    let guard = 0
    while (this.#isDateDisabled(this.#toIsoDate(candidate), candidate.getDay())) {
      if (this.minValue && this.#toIsoDate(candidate) < this.minValue && step < 0) {
        return;
      }

      if (this.maxValue && this.#toIsoDate(candidate) > this.maxValue && step > 0) {
        return;
      }

      if (guard++ >= maximumDatesToExamine) return;

      candidate.setDate(candidate.getDate() + step)
    }

    return candidate;
  }

  focusedValueChanged() {
    if (!this.focusedValue) return;

    const candidate = new Date(this.focusedValue + "T00:00:00");

    // Navigate to a different month if the candidate is outside the current view
    if (candidate.getFullYear() !== this.yearValue || candidate.getMonth() !== this.monthValue) {
      this.yearValue = candidate.getFullYear()
      this.monthValue = candidate.getMonth()
      this.renderCalendar()
    }
    const previouslyFocusedDayBtn = this.gridTarget.querySelector(`button[tabindex="0"]`);

    if (previouslyFocusedDayBtn) previouslyFocusedDayBtn.tabIndex = -1;

    const newlyFocusedDayButton = this.gridTarget.querySelector(`button[data-date-picker-date-param="${this.focusedValue}"]`);

    if (newlyFocusedDayButton) {
      newlyFocusedDayButton.tabIndex = 0;
      newlyFocusedDayButton.focus({ focusVisible: true });
    }
  }
}
