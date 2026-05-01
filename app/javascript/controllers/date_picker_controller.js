import { Controller } from "@hotwired/stimulus"

// Custom date picker.
//
// Data attributes on the controller element:
//   data-date-picker-disabled-value  JSON array of ISO dates to disable, e.g. '["2026-04-24","2026-04-27"]'
//   data-date-picker-marked-value    JSON array of ISO dates to mark with a dot, e.g. '["2026-04-23"]'
//   data-date-picker-min-value       ISO date string; any date before this is disabled, e.g. '"2026-04-23"'
//
// Targets:
//   input       hidden <input> that holds the selected ISO date value
//   display     clickable element (button/span) that shows the formatted date and opens/closes the calendar
//   calendar    the popup wrapper div
//   monthLabel  element where the current month/year label is rendered
//   grid        element where the day buttons are rendered
export default class extends Controller {
  static targets = ["input", "calendar", "display", "monthLabel", "grid", "announce"]
  static values = { disabled: Array, marked: Array, min: String }

  connect() {
    const initial = this.inputTarget.value
    let seed = initial ? new Date(`${initial}T00:00:00`) : new Date()
    // If no date is selected but a minValue exists in a future month (e.g. the earliest
    // available appointment is May 5 but today is April 30), open the calendar to that
    // future month instead of the current one so the user sees selectable dates immediately.
    if (!initial && this.minValue) {
      const min = new Date(`${this.minValue}T00:00:00`)
      if (min > seed) seed = min
    }
    this.viewYear = seed.getFullYear()
    this.viewMonth = seed.getMonth() // 0-indexed
    this.renderCalendar()
    document.addEventListener("click", this.#handleOutsideClick)
    this.element.addEventListener("keydown", this.#handleKeydown)
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
    this.displayTarget.setAttribute("aria-expanded", "true")
    // move focus to the selected day, or the first enabled day
    requestAnimationFrame(() => {
      const focused = this.gridTarget.querySelector("button[aria-pressed='true']:not(:disabled)") ||
                      this.gridTarget.querySelector("button:not(:disabled)")
      focused?.focus()
    })
  }

  close() {
    this.calendarTarget.hidden = true
    this.displayTarget.setAttribute("aria-expanded", "false")
    this.displayTarget.focus()
  }

  prevMonth() {
    if (this.viewMonth === 0) { this.viewMonth = 11; this.viewYear-- }
    else { this.viewMonth-- }
    this.renderCalendar()
  }

  nextMonth() {
    if (this.viewMonth === 11) { this.viewMonth = 0; this.viewYear++ }
    else { this.viewMonth++ }
    this.renderCalendar()
  }

  selectDay(event) {
    const date = event.currentTarget.dataset.date
    this.inputTarget.value = date
    this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))
    const formatted = this.#formatDisplay(date)
    this.displayTarget.textContent = formatted
    this.announceTarget.textContent = `Selected ${formatted}`
    this.close()
    this.renderCalendar() // re-render to reflect selection
  }

  renderCalendar() {
    const { viewYear: year, viewMonth: month } = this
    this.monthLabelTarget.textContent = new Date(year, month, 1)
      .toLocaleDateString("en-US", { month: "long", year: "numeric" })

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
      weekDays.forEach(day => {
        const td = tr.insertCell()
        if (day === null) return

        const isoDate = [
          year,
          String(month + 1).padStart(2, "0"),
          String(day).padStart(2, "0")
        ].join("-")

        const isDisabled = this.disabledValue.includes(isoDate) ||
          (this.minValue && isoDate < this.minValue)
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
        btn.dataset.date = isoDate
        btn.dataset.action = "click->date-picker#selectDay"
        btn.disabled = isDisabled
        btn.setAttribute("aria-pressed", String(isSelected))
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
  }

  // --- private ---

  #formatDisplay(isoDate) {
    const [y, m, d] = isoDate.split("-").map(Number)
    return new Date(y, m - 1, d).toLocaleDateString("en-US", {
      month: "long", day: "numeric", year: "numeric"
    })
  }

  #handleOutsideClick = (event) => {
    if (!this.element.contains(event.target)) this.close()
  }

  #handleKeydown = (event) => {
    if (event.key === "Escape" && !this.calendarTarget.hidden) {
      event.stopPropagation()
      this.close()
    }
  }
}
