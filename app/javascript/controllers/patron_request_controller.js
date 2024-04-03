import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['earliestAvailable']

  connect() { }

  async updateEarliestAvailable(event) {
    const url = new URL(this.earliestAvailableTarget.src + "/../" + event.currentTarget.value);

    this.earliestAvailableTarget.src = url;
  }
}
