import { Controller } from "@hotwired/stimulus"

// Controller for making button populate with selected activities
export default class extends Controller {
  static targets = ['selected']
  static values = { selected: Array }

  change(event) {
    const title = event.currentTarget.dataset.title;
    const activityId = event.currentTarget.value;

    if (event.currentTarget.checked) {
      this.selectedTarget.innerHTML += this.template(title, activityId)
    } else {
      this.remove(event)
    }
  }


  remove(event) {
    const id = event.currentTarget.dataset.activityId
    this.element.querySelector(`input[data-activity-id='${id}']`).checked = false
    this.selectedTarget.querySelector(`[data-id='${id}']`).remove()
  }

  template(title, id) {
   return  `
      <span data-id="${id}">
        <span class="btn-group applied-filter constraint filter filter-subject_ssim">
          <span class="constraint-value btn btn-outline-secondary">
            <span class="filter-value" title="${title}">${title}</span>
          </span>
          <a class="btn btn-outline-secondary remove" data-action="activity-dropdown#remove" data-activity-id="${id}">
            <span class="blacklight-icons blacklight-icons-remove"><svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-x fs-4" viewBox="0 0 16 16">
                <path d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708"></path>
              </svg></span>
            <span class="sr-only visually-hidden">Remove constraint Topic: Theater</span>
          </a>
        </span>
      </span>
    `
  }
}